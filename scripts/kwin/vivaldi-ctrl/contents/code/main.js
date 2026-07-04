let debug = false;

workspace.windowAdded.connect(function(window) {
  if (debug) print("new window:", window.caption);

  window.minimizedChanged.connect(function() {
    const data = {
      "minimizedChanged": window.caption,
      "minimized": window.minimized,
    };
    if (debug) print(JSON.stringify(data));
    callDBus(
      "org.homectrl.Kwin",
      "/Kwin",
      "org.homectrl.Kwin",
      "notify",
      JSON.stringify(data)
    );
  });
});

if (debug) print("vivaldi-ctrl script loaded");
