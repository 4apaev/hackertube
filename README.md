# HackerTube for Apple TV

An unofficial tvOS app for [hackertube.org](https://hackertube.org):
the YouTube videos that Hacker News keeps telling each other to watch.

The app reads the public HackerTube JSON API. Videos play in the YouTube app on the Apple TV.

## Screens
- Home
- Playlists
- Browse
- Library
- Search

lists stay on the Apple TV. They do not sync with the website.

## Requirements

- Xcode 26 with the tvOS platform installed (Xcode > Settings > Components).
- tvOS 18 or later on the Apple TV.
- The YouTube app on the Apple TV.

## Run on your Apple TV

1. Copy `Config/Local.xcconfig.example` to `Config/Local.xcconfig`.
2. In `Local.xcconfig`, set `DEVELOPMENT_TEAM` to your Team ID.
3. In `Local.xcconfig`, set `BUNDLE_ID_PREFIX` to a prefix that no one else uses.
4. Open `HackerTube.xcodeproj` in Xcode.
5. On the Apple TV, open Settings > Remotes and Devices > Remote App and Devices.
6. In Xcode, open Window > Devices and Simulators. Pair the Apple TV.
7. Select the Apple TV as the run destination. Push Run.

Git ignores `Local.xcconfig`. Do not set Team in the Signing & Capabilities tab: Xcode then writes it into `project.pbxproj`.
Without `Local.xcconfig`, the bundle ID is `dev.<your macOS user name>.HackerTube` and simulator builds still work.

With a free Apple ID, the app stops after 7 days. Install it again from Xcode.

## Change the YouTube link

YouTube does not document how other apps open a video in its tvOS app.
The app uses `youtube://watch/<id>`. If the YouTube app opens but
does not play the video, change `YouTube.appURL` in `HackerTube/YouTube.swift`.

If the YouTube app does not open, the app shows a QR code. Scan it to watch on a phone.

## Make targets

Run `make` to see the list.

| Target | Does |
|---|---|
| `make data` | Download the HackerTube data export into `data/` |
| `make playlists` | Write `playlists.html` with the Swift script |
| `make playlists-py` | Write `playlists.html` with the Python script |
| `make assets` | Draw the app icon and Top Shelf images again |
| `make build` | Build the app for the tvOS simulator |
| `make run` | Build, install and start the app in the simulator |
| `make shot` | Save a screenshot of one screen |
| `make clean` | Remove `build/` and `playlists.html` |

Change a variable on the command line, for example `make shot SCREEN=browse SHOT=browse.png`
or `make run SIM="Apple TV"`.

## Screenshots in the simulator

Debug builds read a `-screen` launch argument and open that screen directly.
Use it when you cannot drive the simulator with a remote:

```sh
make shot SCREEN=video:fNk_zzaMoSs SHOT=video.png
```

Values: `playlists`, `browse`, `library`, `search`, `video:<id>`, `playlist:<slug>`, `list:sort=recent`.

## Icons

`scripts/make-assets.swift` draws the app icon and Top Shelf images. Run `make assets` after you change the design.

## YouTube playlist links

`make playlists` writes `playlists.html`: one-click YouTube playlists from the HackerTube data export.

1. Run `make data` to download the data into `data/`.
2. Run `make playlists` (Swift) or `make playlists-py` (Python 3, standard library only).

Both scripts write the same file. They also read the curated playlists from the API.

Each ▶ link opens a temporary YouTube playlist of up to 50 videos. To keep a playlist, save it to your library on YouTube.

## Credits

Data: HackerTube and the [open-index/hacker-news](https://huggingface.co/datasets/open-index/hacker-news) dataset,
[ODC-By 1.0](https://opendatacommons.org/licenses/by/1-0/).

Not affiliated with YouTube, Google, Hacker News or Y Combinator.
