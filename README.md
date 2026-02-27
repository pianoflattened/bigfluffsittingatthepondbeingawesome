# BIG FLUFF SITTING AT THE POND BEING AWESOME
![big fluff, sitting at the pond, being awesome](https://files.catbox.moe/v33v0k.png)

# HOW TO SET UP DEVELOPMENT ENVIRONMENT
[install love](https://love2d.org/wiki/Getting_Started), [download](https://github.com/pianoflattened/bigfluffsittingatthepondbeingawesome/archive/refs/heads/main.zip) the repo, extract & run love in the working directory

# HOW TO DISTRIBUTE AS A GAME
https://love2d.org/wiki/Game_Distribution

# HOW TO ADD A MINIGAME
- draw a fish and put it in the `fish` folder
- make a folder in `scenes` w/ all ur resources
- write the minigame
	- requirements are that it returns a table with `update(dt)`, and `draw` methods. the former should return `fishinhole, 1` to return to the main game & add a point
	- also suggested that the table has `enter` and `leave` methods to clean up
	- use local variables for everything except for the table & methods called directly by love in `main.lua`
	- if you are using a callback not called in `main.lua` you can add it manually
	- current simplest example is `handshake.lua` i think??
- add a line in the table `scene.lua` that: 
	1. requires your script & saves it to a variable
	2. assigns your script file to a fish
		- fish are automatically named internally according to their filenames in the `fish` folder, e.g., `fishes.friend` uses the image `fishes/friend.png`

hope this helps
