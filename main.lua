--- STEAMODDED HEADER
--- MOD_NAME: Extended Blueprint
--- MOD_ID: ExtendedBlueprint
--- PREFIX: exb
--- MOD_AUTHOR: [toneblock]
--- MOD_DESCRIPTION: Increases blueprint compatibility
--- BADGE_COLOUR: 4b68ce
--- DEPENDENCIES: [Steamodded>=1.0.0~ALPHA-1216c]
--- VERSION: 0.3.3
--- PRIORITY: -100

----------------------------------------------
------------MOD CODE -------------------------

local exb = SMODS.current_mod

function exb_parse()
	if G.hand and G.STATE == G.STATES.SELECTING_HAND then
		G.hand:parse_highlighted()
	end
end

-- we are overriding smods functions so priority should be low
function SMODS.four_fingers()
	return math.max(5 - exb_amt("Four Fingers"), 0)
end

function SMODS.shortcut()
	return exb_amt("Shortcut")
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
	if not G.GAME.exb then G.GAME.exb = {} end
	if not G.GAME.exb[_name] then G.GAME.exb[_name] = 0 end
	if amt and G.GAME.exb[_name] >= amt then return true end
	if not amt then return G.GAME.exb[_name] end
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

SMODS.Joker:take_ownership('j_splash', {
	no_mod_badges = true,
	calculate = function(self, card, context)
		if context.repetition and context.full_hand and context.full_hand[1] then
			local poker_hands = evaluate_poker_hand(context.full_hand)
			local top = nil
			for _, v in ipairs(G.handlist) do
				if next(poker_hands[v]) then
					text = v
					top = poker_hands[v][1]
					break
				end
			end
			local inside = false
			for i = 1, #top do
				
				if context.other_card == top[i] then inside = true end
			end
			local initial = false
			if not context.blueprint then
				-- check if self is the leftmost splash. the leftmost splash will be used to score the cards originally
				-- don't do this for bloopies
				for i = 1, #G.jokers.cards do
					if G.jokers.cards[i].ability.name == 'Splash' and G.jokers.cards[i] ~= card then
						break
					elseif G.jokers.cards[i] == card then
						initial = true
						break
					end
				end
			end
			if (not initial) and (not inside) then
				return {
					message = localize('k_again_ex'),
					repetitions = 1,
					card = card
				}
			end
		end
	end
})








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
