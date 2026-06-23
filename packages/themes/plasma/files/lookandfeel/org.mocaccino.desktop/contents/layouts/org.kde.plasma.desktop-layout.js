// Set MocaccinoOS wallpaper on all active desktops
var allDesktops = desktops();
for (var i = 0; i < allDesktops.length; i++) {
    var desktop = allDesktops[i];
    if (desktop.screen === -1) continue;
    desktop.wallpaperPlugin = "org.kde.image";
    desktop.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
    desktop.writeConfig("Image", "file:///usr/share/wallpapers/mocaccino-wallpaper/background.jpg");
}

// Set panel transparency (0=adaptive, 1=opaque, 2=translucent)
var allPanels = panels();
for (var i = 0; i < allPanels.length; i++) {
    allPanels[i].currentConfigGroup = [];
    allPanels[i].writeConfig("opacity", 2);
}
