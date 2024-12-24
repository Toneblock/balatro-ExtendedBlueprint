--- STEAMODDED HEADER
--- MOD_NAME: Extended Blueprint
--- MOD_ID: ExtendedBlueprint
--- PREFIX: exb
--- MOD_AUTHOR: [toneblock]
--- MOD_DESCRIPTION: Increases blueprint compatibility
--- BADGE_COLOUR: 4b68ce
--- DEPENDENCIES: [Steamodded>=1.0.0~ALPHA-1216c]
--- VERSION: 0.2.0

----------------------------------------------
------------MOD CODE -------------------------

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
	local four_fingers = math.min(4, (G.GAME and G.GAME.exb) and G.GAME.exb["Four Fingers"] or 0)
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
	local four_fingers = math.min(4, (G.GAME and G.GAME.exb) and G.GAME.exb["Four Fingers"] or 0)
	local can_skip = math.min(4, (G.GAME and G.GAME.exb) and G.GAME.exb["Shortcut"] or 0)
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
	if _planet and G.GAME.exb and G.GAME.exb["Astronomer"] and G.GAME.exb["Astronomer"] > 0 then
		self.cost = 0 - (G.GAME.exb["Astronomer"] - 1)
	end
end
-- smeared copy
local issuitref = Card.is_suit
function Card:is_suit(suit, bypass_debuff, flush_calc)
	local ret = issuitref(self, suit, bypass_debuff, flush_calc)
	if G.GAME.exb and G.GAME.exb["Smeared Joker"] and G.GAME.exb["Smeared Joker"] >= 2 then
            return true
        end
	return ret
end


SMODS.Atlas({
    key = "modicon",
    path = "exb_icon.png",
    px = 34,
    py = 34
}):register()

----------------------------------------------
------------MOD CODE END----------------------
