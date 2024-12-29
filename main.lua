--- STEAMODDED HEADER
--- MOD_NAME: Extended Blueprint
--- MOD_ID: ExtendedBlueprint
--- PREFIX: exb
--- MOD_AUTHOR: [toneblock]
--- MOD_DESCRIPTION: Increases blueprint compatibility
--- BADGE_COLOUR: 4b68ce
--- DEPENDENCIES: [Steamodded>=1.0.0~ALPHA-1216c]
--- VERSION: 0.3.1

----------------------------------------------
------------MOD CODE -------------------------

local exb = SMODS.current_mod

-- gotta go for smods to do four fingers/shortcut stuff

SMODS.PokerHandPart:take_ownership('_straight', {
	func = function(hand) return exb_get_straight(hand) end
})
SMODS.PokerHandPart:take_ownership('_flush', {
	func = function(hand) return exb_get_flush(hand) end
})


function exb_parse()
	if G.hand and G.STATE == G.STATES.SELECTING_HAND then
		G.hand:parse_highlighted()
	end
end


-- me when i copy the entire functions just to edit a couple lines
function exb_get_flush(hand)
	local ret = {}
	local four_fingers = math.min(4, exb_amt("Four Fingers") or 0)
	local suits = SMODS.Suit.obj_buffer
	if #hand < (5 - (four_fingers)) then return ret else
		for j = 1, #suits do
			local t = {}
			local suit = suits[j]
			local flush_count = 0
			for i=1, #hand do
				if hand[i]:is_suit(suit, nil, true) then flush_count = flush_count + 1;  t[#t+1] = hand[i] end 
			end
			if flush_count >= (5 - (four_fingers)) then
				table.insert(ret, t)
				return ret
			end
		end
		return {}
	end
end

function exb_get_straight(hand)
	local ret = {}
	local four_fingers = math.min(4, exb_amt("Four Fingers") or 0)
	local can_skip = math.min(4, exb_amt("Shortcut") or 0)
	if #hand < (5 - (four_fingers)) then return ret end
	local t = {}
	local RANKS = {}
	for i = 1, #hand do
		if hand[i]:get_id() > 0 then
			local rank = hand[i].base.value
			RANKS[rank] = RANKS[rank] or {}
			RANKS[rank][#RANKS[rank] + 1] = hand[i]
		end
	end
	local straight_length = 0
	local straight = false
	local skipped_rank = can_skip
	local vals = {}
	for k, v in pairs(SMODS.Ranks) do
		if v.straight_edge then
			table.insert(vals, k)
		end
	end
	local init_vals = {}
	for _, v in ipairs(vals) do
		init_vals[v] = true
	end
	if not next(vals) then table.insert(vals, 'Ace') end
	local initial = true
	local br = false
	local end_iter = false
	local i = 0
	while 1 do
		end_iter = false
		if straight_length >= (5 - (four_fingers)) then
			straight = true
		end
		i = i + 1
		if br or (i > #SMODS.Rank.obj_buffer + 1) then break end
		if not next(vals) then break end
		for _, val in ipairs(vals) do
			if init_vals[val] and not initial then br = true end
			if RANKS[val] then
				straight_length = straight_length + 1
				skipped_rank = can_skip
				for _, vv in ipairs(RANKS[val]) do
					t[#t + 1] = vv
				end
				vals = SMODS.Ranks[val].next
				initial = false
				end_iter = true
				break
			end
		end
		if not end_iter then
			local new_vals = {}
			for _, val in ipairs(vals) do
				for _, r in ipairs(SMODS.Ranks[val].next) do
					table.insert(new_vals, r)
				end
			end
			vals = new_vals
			if can_skip and skipped_rank > 0 then
				skipped_rank = skipped_rank - 1
			else
				straight_length = 0
				skipped_rank = can_skip
				if not straight then t = {} end
				if straight then break end
			end
		end
	end
	if not straight then return ret end
	table.insert(ret, t)
	return ret
end

-- we hookin
-- astronomer copies
local setcostref = Card.set_cost
function Card:set_cost()
	setcostref(self)
	local _planet = self.ability.set == 'Planet' or (self.ability.set == 'Booster' and self.ability.name:find('Celestial'))
	if _planet and exb_amt("Astronomer", 1) then
		self.cost = 0 - (exb_amt("Astronomer") - 1)
	end
end
-- smeared copy
local issuitref = Card.is_suit
function Card:is_suit(suit, bypass_debuff, flush_calc)
	local ret = issuitref(self, suit, bypass_debuff, flush_calc)
	if exb_amt("Smeared Joker", 2) then
            return true
        end
	return ret
end

-- i like coding because you can put your spaghetti in a function and suddenly it's clean code
function exb_amt(_name, amt)
	if amt and (G.GAME.exb and G.GAME.exb[_name]) and G.GAME.exb[_name] >= amt then return true end
	if not amt and (G.GAME.exb and G.GAME.exb[_name]) then return G.GAME.exb[_name] end
end

function exb_truefacecheck(_card)
	local id = 1 -- _card:get_id()
	local rank = SMODS.Ranks[_card.base.value]
	if exb_amt("Pareidolia", 2) and (id > 0 and rank and rank.face) then return true end
end

function exb_pareiupd()
	if G.GAME and G.GAME.blind then
		for _, v in ipairs(G.playing_cards) do
			if exb_truefacecheck(v) then	-- idk if the card update inject covers this but just to be safe
				v:set_debuff(false)
				v.ability.wheel_flipped = false
				if v.area == G.hand and v.facing == 'back' then
                			v:flip()
				end
			else
				G.GAME.blind:debuff_card(v)
				if v.area == G.hand and v.facing == 'front' and G.GAME.blind:stay_flipped(G.hand, v) then
					v:flip()
					v.ability.wheel_flipped = true
				end
			end
    		end
	end
end

function exb_jokerlock()
	return exb.config.lock and (G.GAME and G.GAME.STOP_USE and G.GAME.STOP_USE > 0 and (G.STATE == G.STATES.HAND_PLAYED or G.STATE == G.STATES.NEW_ROUND or G.STATE == G.STATES.ROUND_EVAL))
end










-- config time!
-- tysm larswijn (https://discord.com/channels/1116389027176787968/1233186615086813277/1298441528712101940)

exb.config_tab = function()
  return {n=G.UIT.ROOT, config = {align = "cm", padding = 0.05, r = 0.1, colour = G.C.BLACK}, nodes = {
    create_toggle{ 
      label = "Lock joker positions on hand played", 
      w = 0,
      ref_table = exb.config, 
      ref_value = "lock" 
    }
  }}
end

SMODS.Atlas({
    key = "modicon",
    path = "exb_icon.png",
    px = 34,
    py = 34
}):register()

----------------------------------------------
------------MOD CODE END----------------------
