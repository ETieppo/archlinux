glide.keymaps.set("normal", "<Space><Space>", async () => {
  await glide.keys.send("<C-l>");
}, { description: "abrir barra de URL" });

glide.prefs.set("ui.key.menuAccessKeyFocuses", false);
