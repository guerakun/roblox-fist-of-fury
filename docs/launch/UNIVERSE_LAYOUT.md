# Two-place source layout

WO-5.1 creates two independent, reproducible Rojo outputs. `default.project.json` builds the four-player campaign into `places/CurtainBreak.rbxl`. `hub.project.json` builds the social refuge into `places/CurtainBreakHub.rbxl` with its own bootstrap/client tree. Shared modules are mapped into both; no campaign bootstrap runs in the hub.

`src/shared/PlaceIds.lua` deliberately contains zero IDs. Teleport adapters must refuse deployments until an owner-approved **test** universe has valid Hub and Campaign IDs. No publication, start-place switch, MaxPlayers edit, sales toggle or Creator Dashboard action is authorized tonight. Proposed capacity is 30 in hub and four in campaign; these are design targets, not changed place settings.

The source hub provides an arrival plaza, deploy terminal, training space, records board and earned-style wardrobe area. Party/deploy UI, functioning dojo and leaderboard data are separate work orders; labels do not certify those features are complete. The initial build uses native geometry, consistent with the original Ashgate setting.

The owner checklist is to create/configure a test universe, insert both reviewed builds, set IDs in source, and run WO-5.6 five real round trips with two accounts. Teleport and published asset permissions cannot be certified by local Studio tests.
