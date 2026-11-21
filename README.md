# NeonKeys

**A portable keyboard and mouse overlay for OBS Studio on Windows.**

Built for Valorant streams on Kick, Twitch, YouTube, or any platform supported by OBS. Show your current key presses and mouse clicks with a transparent Browser Source. No OBS plugin, Python installation, account, or hosted server is required.

![Design and device selector](docs/designs.jpg)

## Features

- Four designs: **Neon**, **Glass**, **Minimal**, and **Arcade**.
- Show keyboard only, mouse only, or both.
- Three color palettes for Neon, Glass, and Arcade; monochrome Minimal.
- Custom streamer name, live preview, and animated preview demo.
- Copy an OBS URL containing your selected design, device, colors, and name.
- Single executable with the panel and overlay embedded inside it.
- System tray controls to open the panel, pause input display, copy the default OBS URL, or quit.
- No input history, analytics, or external input server.

## Get started

1. Download `NeonKeys.exe` from this repository's **Releases**, or build it below.
2. Run it on the **same Windows computer as your keyboard, mouse, and OBS**.
3. In the browser panel, choose a design and device, then click **Adresi kopyala**.
4. In OBS, add **Sources → + → Browser**. Leave **Local file** unchecked and paste the copied URL.
5. Set the width and height shown in the panel, use **60 FPS**, and place the source above your game capture.
6. Keep NeonKeys running in the tray. You may close the browser panel.

| Device | Width | Height |
| --- | ---: | ---: |
| Keyboard + mouse | 560 | 400 |
| Keyboard only | 460 | 400 |
| Mouse only | 260 | 360 |

Panel: `http://127.0.0.1:47831/`

Default OBS source: `http://127.0.0.1:47831/overlay`

`127.0.0.1` means **the computer opening the address**. Every streamer runs their own copy and sees only their own input. This is a local companion app, not a hosted page that can read keyboard input from other applications by itself. Two-computer streaming setups are not supported by this version.

When changing a design or device, copy the new URL into OBS and update its source dimensions. The panel remembers preferences in that browser's local storage. The animated demo applies only to the preview; the copied OBS URL uses real input.

## Windows requirements

- Windows 10 or Windows 11 with .NET Framework 4.x (normally included).
- OBS Studio with Browser Source support.
- No administrator permission is requested.
- The executable is unsigned. Build from source if you prefer to inspect it yourself.

The UI is currently Turkish. The ability captions match default Valorant bindings; custom in-game bindings do not change the captions automatically.

## Build from source

Open PowerShell in the repository folder and run:

```powershell
.\build.ps1
```

Outputs:

```text
dist/NeonKeys.exe
dist/NeonKeys.zip
dist/SHA256SUMS.txt
```

The script uses the C# compiler included with .NET Framework. The HTML files are embedded at compile time. No package downloads or API keys are needed.

An optional integration smoke check starts the standalone executable, verifies the embedded panel, overlay, event stream, and local origin restriction, then stops its own process:

```powershell
.\scripts\smoke.ps1
```

Close an existing NeonKeys instance before running that check. GitHub Actions runs the build and smoke check for pushes and pull requests. Pushing a `v*` tag builds and publishes a release with the executable, ZIP, and checksums.

## Input and privacy

The app polls a fixed list of displayed keys using the Windows `GetAsyncKeyState` API. It reads mouse button presses, not mouse movement or wheel scrolling. It does not inject input, modify the game, or attach to the game process.

Current pressed-key state is sent to local browser sources using Server-Sent Events. The HTTP server listens only on IPv4 loopback and rejects unrelated Host/Origin headers. Pressed-key state is held in memory and is not written to disk. Pause display from the tray before entering private information on stream.

## Known limits

- Valorant/Vanguard behavior has **not been verified in an active game**. This project does not promise anti-cheat certification or compatibility.
- Keyboard layout is a compact WASD/Valorant layout, not a full keyboard.
- Input is sampled, so extremely short taps between samples may be missed.
- Port `47831` must be available. Only one NeonKeys instance runs per Windows session.
- This initial version uses a small local HTTP server intended for personal streaming workloads.

## Contributing

Bug reports, translations, new designs, and pull requests are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md). Licensed under the [MIT License](LICENSE).

---

## Türkçe kullanım

NeonKeys, OBS yayınında bastığın tuşları ve fare tıklamalarını gösteren taşınabilir bir Windows uygulamasıdır.

1. **Releases** bölümünden `NeonKeys.exe` indir ve kendi bilgisayarında aç.
2. Panelden **Neon / Glass / Minimal / Arcade** tasarımlarından birini seç.
3. **Yalnızca klavye / Yalnızca fare / Klavye + Fare** seçimini yap.
4. Renk ve yayıncı adını ayarla, **Adresi kopyala** düğmesine bas.
5. OBS → **Kaynaklar → + → Tarayıcı** ekle. **Yerel dosya** kapalı olsun.
6. Adresi yapıştır; panelde gösterilen genişlik ve yüksekliği kullan, FPS değerini **60** yap.

Seçim değiştirince OBS adresini ve ölçülerini güncelle. Uygulama sistem tepsisinde açık kalmalıdır. Saatin yanındaki simgeden duraklatabilir veya kapatabilirsin. Tek başına EXE dosyasını başkalarına gönderebilirsin; herkes kendi bilgisayarında çalıştırır. Tuş geçmişi kaydedilmez. Valorant açıkken test henüz yapılmamıştır.

Kaynak kodundan derlemek için PowerShell'de `./build.ps1` çalıştır. Proje MIT lisansıyla açık kaynaktır.
