// Set MocaccinoOS wallpaper on all active desktops
desktops().forEach(function(desktop) {
    desktop.wallpaperPlugin = "org.kde.image";
    desktop.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
    desktop.writeConfig("Image", "file:///usr/share/wallpapers/mocaccino-wallpaper/background.jpg");
    desktop.reloadConfig();
});
