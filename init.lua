local load_time_start = os.clock()
music = {}
music.loops = {}
function music.reset()
	music.t1 = minetest.get_us_time()
	music.tab = {}
	music.num = 1
end
music.reset()

minetest.register_node("music:play", {
	description = "Play",
	tiles = {"default_steel_block.png^default_papyrus.png","default_steel_block.png^default_papyrus.png",
		"default_wood.png^[transformR270^default_diamond.png^[transformR90"},
	groups = {bendy=2,cracky=1},
	sounds = default.node_sound_stone_defaults(),
	on_construct = function(pos)
		minetest.get_meta(pos):set_string("infotext", "Play")
	end,
	on_punch = function(pos, _, puncher)
		music.status = nil
		for _,i in ipairs(music.tab) do
			minetest.after(i[2], function(pos)
				if not music.status then
					minetest.sound_play(i[1], {pos = pos})
					minetest.chat_send_player(puncher:get_player_name(), i[2]..' '..i[1])
				end
			end, pos)
		end
	end,
})

minetest.register_node("music:record", {
	description = "Record",
	tiles = {"default_tnt_bottom.png^default_rail_crossing.png","default_tnt_bottom.png^default_rail_crossing.png",
		"default_wood.png^heart.png^[transformR180^heart.png^[transformR180"},
	groups = {bendy=2,cracky=1},
	sounds = default.node_sound_stone_defaults(),
	on_construct = function(pos)
		minetest.get_meta(pos):set_string("infotext", "Record")
	end,
	on_punch = function(pos, _, puncher)
		music.status = "recording"
		music.t1 = minetest.get_us_time()
		music.tab = {}
		music.num = 1
		minetest.chat_send_player(puncher:get_player_name(), "num, tab and t1 reset")
	end,
})

minetest.register_node("music:box", {
	description = "Sound Box",
	tiles = {"default_steel_block.png^default_obsidian_glass.png","default_steel_block.png^default_obsidian_glass.png",
		"default_wood.png^default_grass_5.png"},
	groups = {bendy=2,cracky=1},
	sounds = default.node_sound_stone_defaults(),
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", "field[text;;${text}]")
		meta:set_string("infotext", "\"\"")
	end,
	on_receive_fields = function(pos, formname, fields, sender)
		local meta = minetest.get_meta(pos)
		fields.text = fields.text or ""
		minetest.log("action", (sender:get_player_name() or "").." wrote \""..fields.text..
				"\" to soundbox at "..minetest.pos_to_string(pos))
		meta:set_string("text", fields.text)
		meta:set_string("infotext", '"'..fields.text..'"')
	end,
	on_punch = function(pos, _, puncher)
		local meta = minetest.get_meta(pos)
		local soundname = meta:get_string"text"
		if music.status == "recording" then
			local delay = (minetest.get_us_time() - music.t1)/1000000
			music.tab[music.num] = {soundname, delay}
			music.num = music.num+1
			minetest.chat_send_player(puncher:get_player_name(), delay.." "..soundname)
		end
		minetest.sound_play(soundname, {pos = pos})
	end,
})

minetest.register_node("music:box2", {
	description = "Music Box",
	tiles = {"default_steel_block.png^default_rail_crossing.png","default_steel_block.png^default_rail_crossing.png",
		"default_wood.png^default_leaves.png^default_grass_2.png"},
	groups = {bendy=2,cracky=1},
	sounds = default.node_sound_stone_defaults(),
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", "field[text;;${text}]")
		meta:set_string("infotext", "\"\"")
	end,
	on_receive_fields = function(pos, formname, fields, sender)
		local meta = minetest.get_meta(pos)
		fields.text = fields.text or ""
		minetest.log("action", (sender:get_player_name() or "").." wrote \""..fields.text..
				"\" to musicbox at "..minetest.pos_to_string(pos))
		meta:set_string("text", fields.text)
		meta:set_string("infotext", '"'..fields.text..'"')
	end,
	on_punch = function(pos, _, puncher)
		local meta = minetest.get_meta(pos)
		local soundname = meta:get_string"text"
		local soundnum = tonumber(meta:get_string"hwnd")
		if soundnum then
			minetest.sound_stop(soundnum)
			meta:set_string"hwnd"
			music.loops[soundnum] = nil
			if puncher:get_player_control().sneak then
				return
			end
		end
		soundnum = minetest.sound_play(soundname, {pos = pos, loop=true})
		music.loops[soundnum] = true
		meta:set_string("hwnd", soundnum)
	end,
	on_destruct = function(pos)
		local soundnum = tonumber(minetest.get_meta(pos):get_string"hwnd")
		if soundnum then
			minetest.sound_stop(soundnum)
			music.loops[soundnum] = nil
		end
	end
})

minetest.register_chatcommand("stoploops",{
	description = "stops looped sounds",
	params = "",
	privs = {},
	func = function()
		for i in pairs(music.loops) do
			minetest.sound_stop(i)
			music.loops[i] = nil
		end
	end
})

minetest.log("info", (string.format("[music] loaded after ca. %.2fs", os.clock() - load_time_start)))
