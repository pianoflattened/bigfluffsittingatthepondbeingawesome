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

## SPRITE.LUA EXPLANATION
right now there are three classes to use: actor, effect, & level. an actor is a guy with a location & a bunch of costumes (different pictures it can swap to) & defined animations. an effect is a machine that makes actors w the same set of costumes but diff locations. a level is an actor with a different constructor that takes a table of collision rectangles. a good example of an actor is the cloud in `scenes/typer.lua`. a good example of an effect is the splash in `scenes/fishinhole.lua`. a good example of a level is the lake, also in `scenes/fishinhole.lua`

the constructor for actor takes a `basepath` (which is the directory your minigame files are in, ending with a slash) & the `name` of the image to look for. if you do not supply a file extension it will assume it is looking for a png file. it also optionally takes a `transform` object OR a table specifying the differences between the desired & default transform object. more on what that means later

when actor:draw() is called, it chooses which image to draw by indexing a table of costumes with the value its `costume` field. this means that if you want to change which image is drawn at the actor's location, you have to set the actor's `costume` field to the corresponding key. these keys are defined when you pass the`name` to the actor constructor or to `addcostume`/`addcostumes`. so if you used `guy:addcostume(basepath, "jumping")` it will load `basepath.."jumping.png"` as an image which can be switched to when you set `guy.costume = "jumping"`. pretty simple

all actors have x, y, height, & width. you know what these do

a transform object specifies translation (`dx`, `dy`), rotation (`dr`), scale (`sx`, `sy`), and offset (`ox`, `oy`). offset is used to determine which pixel will be at the precise (x, y) coordinate you tell the actor to move to. the translation fields `dx` and `dy` are not meant to be used to change the position of anything that matters. mostly i use them for jitter effects, like the shaking letters in `typer` and the line when it snags in `fishinhole`. often when you want to supply a transform object, i have also given you the option to, instead of writing out the whole constructor, give a table that only defines the values you need to define. you can find a lot of this at the top of `scenes/fishinhole.lua`, where the last argument to `actor:new` is often a table such as `{ox = 99, oy = 165}`

actors have `actions` and `states`. you define them using `action:new` by giving lists of `frame` data. each frame has:
- a transform AND/OR a costume (to apply for the frame's duration)
- EITHER a time (which the constructor will make into a timer) OR a test
the costume will always be a string. transform is either a transform object OR a function. originally this function was meant to return a transform object, but it very quickly turned into an arbitrary callback that modified the actor. the callback gives you a reference to the actor, dt, and a reference to the timer (if there is one)

when the timer runs out OR the test returns true, that tells `actor:update` to move on to the next frame. a test also has a bonus optional return value `n`, which specifies the number of frames to advance when the test returns true. n can be negative, but you can also, in the `action` constructor, follow your list of framedata with `true` if all you want is for your action to loop rather than end

if you are planning on using the actions, you need to call `actor:update(dt)` inside your minigame's `update` method. you can do this anywhere you like so long as you keep in mind that changes made after `actor:update` is called will not apply until the next run-around of `update`. you will also want to use `actor:start("action")`, & probably also `actor:stop("action")`. these functions respectively ensure that the actor either has or does not have the action in its `state` table. this `state` table is iterated on by `actor:update`, & each corresponding action is run. actions that end on their own are also removed from the `state` table. note that this means any actor can have multiple states at once. there is a helpful `actor:is("action")` function for checking whether or not the `state` table contains an action

`effect` is a lot like an actor except it cannot be drawn on its own. it makes actors with its method `spawn` & adds them to the table `effect.spots` which is meant for you to iterate over & do as you please with each produced actor. there is currently a function `effect.destroy` which sets a flag for removal, but the class itself will not remove anything on its own
