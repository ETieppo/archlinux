glide.keymaps.set("normal", "<Space><Space>", async () => {
  await glide.keys.send("<C-l>");
}, { description: "abrir barra de URL" });
