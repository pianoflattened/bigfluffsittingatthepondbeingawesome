# BIG FLUFF SITTING AT THE POND BEING AWESOME
![big fluff, sitting at the pond, being awesome](https://files.catbox.moe/v33v0k.png)

# HOW TO SET UP DEVELOPMENT ENVIRONMENT
[install love](https://love2d.org/wiki/Getting_Started), [download](https://github.com/pianoflattened/bigfluffsittingatthepondbeingawesome/archive/refs/heads/main.zip) the repo, extract & run love in the working directory

# HOW TO DISTRIBUTE AS A GAME
https://love2d.org/wiki/Game_Distribution

# HOW TO ADD A MINIGAME
- make a folder in `scenes` w/ all ur resources
- write the script
	- requirements are that it returns a table with `init`, `update(dt)`, and `draw` methods & at some point uses `gs.switch(fishinhole)` to return to the main game
	- also suggested that the table has a `basepath` field & a `leave` method to clean up
	- do not make any global variables that dont apply across every minigame. if u dk what to assign a variable to, assign it to the minigame's table
	- current simplest example is `handshake.lua`
- add a line in the table `scene.lua` that assigns your script file to a fish
	- fish are automatically named internally according to their filenames in the `fish` folder, e.g., `fishes.friend` uses the image `fishes/friend.png`

hope this helps
