{{flutter_js}}
{{flutter_build_config}}

// 🛡️ Forces the WebGL CanvasKit initialization process locally
_flutter.loader.load({
  onEntrypointLoaded: async function(engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine({
      // Specifies the local WebGL context to completely bypass gstatic download limits
      canvasKitVariant: "auto"
    });
    await appRunner.runApp();
  }
});