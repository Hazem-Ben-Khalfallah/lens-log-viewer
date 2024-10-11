# lens-log-viewer README

The lens-log-viewer provides a Json log viewer for Lens. 

## Features

This plugin adds a menu item to the Pods menu in Lens. When clicked, it will open a new terminal with the customized log viewer.

## Requirements

1. Download `log-viewer.sh` file ad put it under a `PATH` that you choose. 
2. Create a symbolic link by executing the following command 
```bash
sudo ln -s /PATH/log-viewer.sh /usr/local/bin/log-viewer
```
3. Verify you installation by executing the following command
```bash
log-viewer -h
```

## Installation Instructions

Start the Lens is running, and follow these simple steps:

1. Go to Extensions view (Menu -> File -> Extensions)
2. Enter the name of this extension, `@hazem-ben-khalfallah/lens-log-viewer`
3. Click on the Install button
4. Make sure the extension is enabled (Lens → Extensions)

You may or may not need to refresh (or re-open) Lens for the plugin to render
the menu item. This may be necessary if Lens is already open on the Pods workload.

## Known Issues

On initial install, the bunyan log viewer may not appear in the menu. If this
occurs, refresh Lens and it should appear.

## Release Notes

Enjoy!

### 0.0.1

Initial release of the lens-log-viewer contains minimal functionality and allows
for the viewing of Logs through the use of the `log-viewer` command line tool.

## Credits
Special thanks to [Jeremy Dinsel](https://github.com/jdinsel-xealth) for his lens extension [bunyan-lens-ext](https://github.com/jdinsel-xealth/bunyan-lens-ext).