# GroupHandler

A lightweight Roblox Luau module for retrieving and checking Roblox group information. `GroupHandler` provides methods to retrieve a player's highest eligible role, get their rank, and check whether they have a specific role in a group.

The module uses `GroupService:GetRolesInGroupAsync()` and includes an internal cache to reduce redundant API requests.

## Features

- Retrieve a player's highest role in a group.
- Retrieve a player's numerical group rank.
- Check whether a player has a specific role.
- Accept both `Player` instances and UserIds.
- Automatically cache group data per player and group.
- Automatically clear cached data when a player leaves.
- Exclude bracketed roles (e.g. `[Developer]`) when determining the highest role.
- Usable from both the client and server.

## Installation

1. Download the [GroupHandler source code](https://github.com/CombineBenefactor/GroupHandler/blob/main/source/GroupHandler.lua).
2. Create a ModuleScript named `GroupHandler`.
3. Place the ModuleScript inside `ReplicatedStorage`.
4. Require the module from a LocalScript or server-side Script.

**Recommended hierarchy:**

```text
ReplicatedStorage
└── GroupHandler (ModuleScript)
```

**Requiring the module:**

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GroupHandler = require(ReplicatedStorage:WaitForChild("GroupHandler"))
```

> **Note:** Although the module can be required from both client and server scripts, group information retrieval is performed through Roblox's GroupService. For security-sensitive authorization checks, always perform the actual permission validation on the server. Client-side checks should only be used for presentation purposes.

## Configuration

The module has a configurable default group ID:

```lua
local Default_Group: number = 0
```

Change this value to your Roblox group's ID.

When calling a method without specifying a group ID, the module automatically uses this default group.

## API Reference

All methods accept either a `Player` instance or a numerical UserId as their target.

### `GetRankInGroup(Target, Group?)`

Returns the numerical rank of the player's highest eligible role in the specified group.

**Parameters:**
- `Target` (`Player | number`) – The player instance or UserId.
- `Group` (`number?`) – The group ID. Defaults to `Default_Group`.

**Returns:**
- `number` – The highest eligible role's rank. Returns `0` if the player is not a member or has no eligible role.

**Example:**

```lua
local Rank = GroupHandler.GetRankInGroup(Player, 123456789)

if Rank >= 100 then
    print("Player has a rank of at least 100.")
end
```

You can also omit the group ID:

```lua
local Rank = GroupHandler.GetRankInGroup(Player)
```

### `GetHighestRoleInGroup(Target, Group?)`

Returns the name of the player's highest eligible role in the specified group.

**Parameters:**
- `Target` (`Player | number`) – The player instance or UserId.
- `Group` (`number?`) – The group ID. Defaults to `Default_Group`.

**Returns:**
- `string` – The highest eligible role's name. Returns an empty string if the player is not a member or has no eligible role.

**Example:**

```lua
local Role = GroupHandler.GetHighestRoleInGroup(Player, 123456789)

print("Player's highest role:", Role)
```

### `HasRoleInGroup(Target, Group, RoleName)`

Checks whether the player has a specific role in the specified group.

**Parameters:**
- `Target` (`Player | number`) – The player instance or UserId.
- `Group` (`number`) – The group ID.
- `RoleName` (`string`) – The exact name of the role to check.

**Returns:**
- `boolean` – `true` if the player has the specified role, otherwise `false`.

**Example:**

```lua
if GroupHandler.HasRoleInGroup(Player, 123456789, "Administrator") then
    print("Player is an administrator.")
end
```

## Usage Examples

### Checking a player's rank

```lua
local Rank = GroupHandler.GetRankInGroup(Player)

if Rank >= 200 then
    print("Player is authorized.")
end
```

### Checking for a specific role

```lua
if GroupHandler.HasRoleInGroup(Player, 123456789, "Moderator") then
    print("Welcome, Moderator!")
end
```

### Using a UserId instead of a Player instance

```lua
local UserId = 123456789

local Rank = GroupHandler.GetRankInGroup(UserId)
local Role = GroupHandler.GetHighestRoleInGroup(UserId)

print(Rank, Role)
```

### Combining multiple checks

```lua
local Rank = GroupHandler.GetRankInGroup(Player, 123456789)
local Role = GroupHandler.GetHighestRoleInGroup(Player, 123456789)

if Rank >= 200 or Role == "Administrator" then
    print("Access granted.")
end
```

## Role Filtering

When determining the highest role, the module filters out roles whose names start with `[` and end with `]`.

For example:

| Role name | Considered |
|---|---|
| `[Developer]` | No |
| `[Contributor]` | No |
| `Administrator` | Yes |
| `Moderator` | Yes |
| `Member` | Yes |

This allows bracketed roles to be ignored when determining a player's highest eligible role.

**Important:** `HasRoleInGroup()` does not apply this filtering. It checks every role returned by Roblox, including bracketed roles.

## Caching

Group information is cached internally using the following structure:

```lua
Cache[UserId][GroupId]
```

Once group data has been retrieved successfully, subsequent requests for the same user and group return the cached result instead of making another API request.

The cache is automatically cleared when a player leaves the server through `Players.PlayerRemoving`.

**Note:** Cached data is not automatically refreshed while the player remains in the server. Changes to a player's group membership or roles may therefore not be reflected until the cache is cleared or the player rejoins.

## Error Handling

Group data retrieval is wrapped in `pcall()` to prevent API errors from interrupting execution.

If Roblox fails to retrieve the group information, the module:
- Prints a warning to the server output.
- Returns `nil` internally.
- Allows the public methods to return their respective fallback values.

| Method | Fallback |
|---|---|
| `GetRankInGroup()` | `0` |
| `GetHighestRoleInGroup()` | `""` |
| `HasRoleInGroup()` | `false` |

Invalid targets (anything other than a `Player` instance or numerical UserId) trigger an assertion error.

## Requirements & Limitations

- Designed for both client-side and server-side execution.
- Recommended to be placed in `ReplicatedStorage`.
- Requires Roblox's `GroupService`.
- Group information retrieval is asynchronous internally.
- Group data is cached for the lifetime of the player's server session.
- The module does not provide cache invalidation or manual refresh functionality.
- The highest eligible role is determined from the order of roles returned by Roblox, after bracketed roles are removed.
- Client-side results must never be trusted for server-side permission enforcement.

## License

This project is licensed under the [BSD Zero Clause License (0BSD)](LICENSE).
