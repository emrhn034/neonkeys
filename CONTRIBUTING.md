# Contributing to NeonKeys

Keep changes focused and describe what a streamer sees before and after your change.

1. Fork the repository and create a branch.
2. Edit `NeonKeys.cs`, `panel.html`, or `overlay.html` as needed.
3. Run `./build.ps1` on Windows.
4. Close any existing NeonKeys instance, then run `./scripts/smoke.ps1`.
5. For visual changes, preview every affected design in keyboard, mouse, and combined modes. Check OBS dimensions and provide a screenshot in your pull request.

Use actual input to confirm press/release behavior. Mark any game compatibility claim with the game and environment tested. Do not add logging of typed text, analytics, external input transmission, or administrator requirements without discussing the need first.

Report bugs with your Windows and OBS versions, selected design/device, expected behavior, and reproduction steps. Do not include passwords, access tokens, or private typed input.

By contributing, you agree that your contribution is available under this project's MIT license.
