// Tries to spawn a subprocess — should be denied by --deny-run.
try {
  const command = new Deno.Command("deno", { args: ["--version"] });
  const output = await command.output();
  console.log(new TextDecoder().decode(output.stdout));
} catch (e) {
  console.error(e);
  Deno.exit(1);
}
