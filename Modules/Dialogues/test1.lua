local module = {}

module.font = "assets/Volter__28Goldfish_29.ttf"
module.dialogue = {
	[1] = {
        autoSkip = true,
		textSpeed = .05,
		endDelay = 1,
		speaker = "Joe mama",
		text = "Hey! this is a very long test because i need to test the text boundaries and dont really know when to stop! >:3",
	},
	[2] = {
        autoSkip = false,
		textSpeed = .05,
		endDelay = 1,
		speaker = "Joe mama",
		text = "testing for simbols now ! @ # $ % * ${1230 2019480129401284012849021}",
	},
}

return module
