using System;
using System.IO;
using System.Net;
using System.Net.Sockets;
using System.Text;
using System.Threading;
using System.Runtime.InteropServices;
using System.Windows.Forms;
using System.Drawing;
using System.Reflection;

class NeonKeys {
    [DllImport("user32.dll")] static extern short GetAsyncKeyState(int key);
    static volatile bool running = true, paused = false;
    static string state = "[]";
    static readonly object gate = new object();
    static readonly int[] keys = {1,2,4,9,16,17,18,27,32,49,50,51,52,53,65,67,68,69,70,71,81,82,83,84,86,87,88,90};
    static TcpListener listener;
    static NotifyIcon tray;
    const int port = 47831;

    [STAThread] static void Main(string[] args) {
        bool first;
        using (var mutex = new Mutex(true, "Local\\NeonKeysOverlay47831", out first)) {
            if (!first) { OpenPanel(); return; }
            Application.EnableVisualStyles();
            try { listener = new TcpListener(IPAddress.Loopback, port); listener.Start(); }
            catch (Exception e) { MessageBox.Show("NeonKeys baslatilamadi: " + e.Message); return; }
            var menu = new ContextMenuStrip();
            menu.Items.Add("Kontrol panelini ac", null, delegate { OpenPanel(); });
            menu.Items.Add("OBS adresini kopyala", null, delegate { Clipboard.SetText("http://127.0.0.1:" + port + "/overlay"); });
            var pause = menu.Items.Add("Tuş gösterimini duraklat");
            pause.Click += delegate { paused = !paused; pause.Text = paused ? "Tuş gösterimini sürdür" : "Tuş gösterimini duraklat"; };
            menu.Items.Add("Kapat", null, delegate { Application.Exit(); });
            tray = new NotifyIcon { Icon = SystemIcons.Application, Text = "NeonKeys — OBS klavye katmanı", ContextMenuStrip = menu, Visible = true };
            tray.DoubleClick += delegate { OpenPanel(); };
            new Thread(Poll) { IsBackground = true }.Start();
            new Thread(Serve) { IsBackground = true }.Start();
            if (Array.IndexOf(args, "--no-panel") < 0) OpenPanel();
            Application.Run();
            running = false; listener.Stop(); tray.Visible = false; tray.Dispose();
        }
    }
    static void OpenPanel() { System.Diagnostics.Process.Start("http://127.0.0.1:" + port + "/"); }
    static void Poll() {
        while(running) {
            var b = new StringBuilder("[");
            if (!paused) foreach (int key in keys) if ((GetAsyncKeyState(key) & 0x8000) != 0) { if(b.Length > 1) b.Append(','); b.Append(key); }
            b.Append(']'); lock(gate) state = b.ToString();
            Thread.Sleep(8);
        }
    }
    static void Serve() {
        while (running) try { var client = listener.AcceptTcpClient(); ThreadPool.QueueUserWorkItem(delegate { Handle(client); }); }
        catch { if (!running) return; }
    }
    static void Handle(TcpClient client) {
        using(client) try {
            client.NoDelay = true; client.ReceiveTimeout = 3000; client.SendTimeout = 3000;
            var stream = client.GetStream();
            var reader = new StreamReader(stream, Encoding.ASCII, false, 1024, true);
            string request = reader.ReadLine(); if(request == null) return;
            string line, host = "", origin = ""; int count = 0;
            while(!String.IsNullOrEmpty(line = reader.ReadLine())) {
                if (++count > 64 || line.Length > 8192) return;
                if(line.StartsWith("Host:", StringComparison.OrdinalIgnoreCase)) host = line.Substring(5).Trim();
                if(line.StartsWith("Origin:", StringComparison.OrdinalIgnoreCase)) origin = line.Substring(7).Trim();
            }
            if(host != "127.0.0.1:" + port || (origin != "" && origin != "http://127.0.0.1:" + port)) { Reply(stream,"403 Forbidden","text/plain","Forbidden"); return; }
            var parts = request.Split(' ');
            if(parts.Length < 2 || parts[0] != "GET") { Reply(stream,"405 Method Not Allowed","text/plain","GET only"); return; }
            string path = parts[1].Split('?')[0];
            if(path == "/events") {
                Write(stream,"HTTP/1.1 200 OK\r\nContent-Type: text/event-stream\r\nCache-Control: no-store\r\nX-Content-Type-Options: nosniff\r\nConnection: close\r\n\r\n");
                string previous = null; int idle = 0;
                while(running) {
                    string current; lock(gate) current = "{\"keys\":" + state + ",\"paused\":" + (paused ? "true" : "false") + "}";
                    if(current != previous || ++idle >= 60) { Write(stream,"data: " + current + "\n\n"); previous = current; idle = 0; }
                    Thread.Sleep(16);
                }
                return;
            }
            string filename = path == "/" ? "panel.html" : path == "/overlay" ? "overlay.html" : null;
            if(filename == null) { Reply(stream,"404 Not Found","text/plain","Not found"); return; }
            using (var resource = Assembly.GetExecutingAssembly().GetManifestResourceStream("NeonKeys." + filename))
            using (var text = new StreamReader(resource, Encoding.UTF8))
                Reply(stream,"200 OK","text/html; charset=utf-8",text.ReadToEnd());
        } catch { }
    }
    static void Write(NetworkStream stream, string text) { byte[] bytes = Encoding.UTF8.GetBytes(text); stream.Write(bytes,0,bytes.Length); }
    static void Reply(NetworkStream stream, string status, string type, string text) {
        byte[] bytes = Encoding.UTF8.GetBytes(text);
        Write(stream,"HTTP/1.1 " + status + "\r\nContent-Type: " + type + "\r\nContent-Length: " + bytes.Length + "\r\nCache-Control: no-store\r\nX-Content-Type-Options: nosniff\r\nConnection: close\r\n\r\n");
        stream.Write(bytes,0,bytes.Length);
    }
}
