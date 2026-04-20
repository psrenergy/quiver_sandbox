// left-pad is not in the project lockfile. Under the default policy
// (lockfile + --frozen), the import must fail before the script runs.
// With allowArbitraryPackages=true, the import is fetched and the script
// runs to completion.
import leftPad from "npm:left-pad@1.3.0";
console.log(leftPad("ok", 5, "0"));
