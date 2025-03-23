local MOD = {
	id = "MIJ",
	name = "My Interesting Jokers",
	version = "1.0.0",
	mod_version = "1.0.0",
	dependencies = {},
	enabled = true,
	icon = "Mods/MIJ/icon.png",
}

local joker_introverted_messages =
{ "They don't know that I'm here..", "This party is nice.. I guess", "I'm not a people's joker.." }

local joker_succ_messages =
{ "Who said you could rest?", "Daww..", "But I was having fun.." }

local joker_unloyal_messages =
{ "Poisoned", "Stabbed", "Overthrown" }

local joker_wally_effects =
{ "misprint", "glass", "destroy-pair", "negative" }

-- Creates an atlas for cards to use
SMODS.Atlas({
	-- Key for code to find it with
	key = "mij",
	-- The name of the file, for the code to pull the atlas from
	path = "mij-jokers.png",
	-- Width of each sprite in 1x size
	px = 71,
	-- Height of each sprite in 1x size
	py = 95,
})

function PrintTable(tbl, prefix)
	-- Function to recursively print table contents with key paths
	for key, value in pairs(tbl) do
		local keyPath = prefix .. (prefix == "" and "" or ".") .. tostring(key)
		if type(value) == "table" then
			PrintTable(value, keyPath)
		else
			sendInfoMessage(keyPath .. ": " .. tostring(value), "mijDebug")
		end
	end
end

function printDebugInfo()
	-- Print current_round structure
	sendInfoMessage("===== CURRENT ROUND =====", "mijDebug")
	PrintTable(G.GAME.current_round, "current_round")

	-- Print round_resets structure
	sendInfoMessage("===== ROUND RESETS =====", "mijDebug")
	PrintTable(G.GAME.round_resets, "round_resets")
end

local jokers = {
	{
		key = "grug_economics",
		name = "Grug Economics",
		slug = "grug_economics",
		rarity = 1,
		cost = 3,
		pos = {
			x = 0,
			y = 0,
		},
		config = {},
		loc_txt = {
			name = "Grug Economics",
			text = {
				"Gain {C:money}$2{} for each",
				"{C:attention}Stone{} card you own",
				"at the end of a {C:attention}Small Blind{}",
			},
		},
		sprite = "j_grug_economics",
		-- SMODS specific function, gives the returned value in dollars at the end of round, double checks that it's greater than 0 before returning.
		calc_dollar_bonus = function(self, card)
			local stone_count = 0
			for _, c in ipairs(G.deck.cards) do
				if c.ability.effect == "Stone Card" then
					stone_count = stone_count + 1
				end
			end
			if stone_count > 0 then
				return stone_count
			end
		end,
		calculate = function(self, card, context)
			-- printDebugInfo()
			if context.end_of_round and not context.repetition and not context.individual then
				if G.GAME.round_resets.loc_blind_states.Big == "Upcoming" then
					-- sendInfoMessage(tostring(G.GAME.round_resets.loc_blind_states.Big == "Upcoming"), "mijDebug")
				end
			end
		end,
	},
	{
		key = "programmer_socks",
		name = "Programmer Socks",
		slug = "programmer_socks",
		rarity = 2,
		cost = 5,
		config = {},
		pos = {
			x = 1,
			y = 0,
		},
		loc_txt = {
			name = "Programmer Socks",
			text = { "Convert played {C:attention}Jacks{}", "into {C:attention}Queens{}" },
		},
		sprite = "j_programmer_socks",
		calculate = function(self, card, context)
			if context.individual and context.cardarea == G.play then
				if context.other_card:get_id() == 11 then
					play_sound("tarot1")
					context.other_card:set_base(G.P_CARDS.H_Q)
					context.other_card:juice_up(0.3, 0.5)
					return {
						message = "Queen!",
					}
				end
			end
		end,
	},
	{
		key = "glass_house",
		name = "Glass House",
		slug = "glass_house",
		rarity = 3,
		cost = 8,
		config = {},
		pos = {
			x = 2,
			y = 0,
		},
		loc_txt = {
			name = "Glass House",
			text = {
				"Gain {X:mult,C:white}x4{} Mult when",
				"using a {C:attention}Stone{} card,",
				"{C:red}1 in 8{} chance to break",
			},
		},
		sprite = "j_glass_house",
		calculate = function(self, card, context)
			if context.individual and context.cardarea == G.play then
				if context.other_card.ability.effect == "Stone Card" then
					local roll = math.random(1, 8)
					if roll == 1 then
						card:shatter()
						return {
							message = "Broke!",
						}
					else
						context.other_card:juice_up(0.3, 0.5)
						return {
							message = "Mult x6!",
							Xmult_mod = 4,
						}
					end
				end
			end
		end,
	},
	{
		key = "introverted_joker",
		name = "The Introverted Joker",
		slug = "introverted_joker",
		rarity = 1,
		cost = 4,
		config = {},
		pos = {
			x = 3,
			y = 0,
		},
		loc_txt = {
			name = "The Introverted Joker",
			text = { "Gain {C:chips}50 chips{} and {C:mult}+10 mult{}", "when your played hand is a high card." },
		},
		sprite = "j_introverted_joker",
		calculate = function(self, card, context)
			if context.individual and context.cardarea == G.play then
				local high_card = context.scoring_name == "High Card"
				if high_card then
					return {
						message = joker_introverted_messages[math.random(1, #joker_introverted_messages)],
						chips = 50,
						mult = 10,
					}
				end
			end
		end,
	},
	{
		key = "unloyal_joker",
		name = "The unloyal Joker",
		slug = "unloyal_joker",
		rarity = 1,
		cost = 4,
		sprite = "j_unloyal_joker",
		config = { extra = { mult = 0 } },
		pos = {
			x = 4,
			y = 0,
		},
		loc_vars = function(self, info_queue, card)
			return {
				vars = {
					card.ability.extra.mult,
				},
			}
		end,
		loc_txt = {
			name = "The Unloyal Joker",
			text = { "When playing a jack,", "destroy all kings and queens in hand;", "and gain {C:mult}2+{} mult", "Current Mult: {C:mult}+#1#{}" },
		},
		calculate = function(self, card, context)
			-- before: This context is used for effects that happen before scoring begins.
			if context.individual and context.cardarea == G.play then
				local shattered = false
				if context.other_card:get_id() == 11 then
					play_sound("tarot1")
					for i = 1, #G.hand.cards do
						if G.hand.cards[i]:get_id() == 12 then
							G.hand.cards[i]:shatter()
							shattered = true
						elseif G.hand.cards[i]:get_id() == 13 then
							G.hand.cards[i]:shatter()
							shattered = true
						end
					end
					if shattered then
						card.ability.extra.mult = card.ability.extra.mult + 2
						return {
							message = joker_unloyal_messages[math.random(1, #joker_unloyal_messages)],
							colour = G.C.RED
						}
					end
				end
			end
			if context.joker_main and context.cardarea == G.jokers and card.ability.extra.mult >= 1 then
				return {
					mult = card.ability.extra.mult,
				}
			end
		end
	},
	{
		key = "insurance_joker",
		name = "Insurance",
		slug = "insurance_joker",
		sprite = "j_insurance_joker",
		rarity = 1,
		cost = 4,
		config = { extra = { per = 25, antes_passed = 0 } },
		pos = {
			x = 5,
			y = 0,
		},
		loc_vars = function(self, info_queue, card)
			return {
				vars = {
					card.ability.extra.per,
					card.ability.extra.antes_passed,
				},
			}
		end,
		loc_txt = {
			name = "Insurance",
			text = {
				"Gain {C:chips}+3 hand size{} and {C:mult}+3 discards{} during a boss blind,",
				"But lose a #1#% of your money [#2#]",
			},
		},
		calculate = function(self, card, context)
			if context.end_of_round and context.cardarea == G.jokers then
				card.ability.extra.antes_passed = card.ability.extra.antes_passed + 1
				if card.ability.extra.antes_passed >= 5 then
					card.ability.extra.antes_passed = 0
					card.ability.extra.per = card.ability.extra.per + 25
					if card.ability.extra.per > 90 then
						card.ability.extra.per = 90
					end
					return {
						message = "Insurance Premium: 25%"
					}
				end
			end
			if context.setting_blind and G.GAME.blind.boss then
				local loss = math.ceil(takePercentage(G.GAME.dollars, card.ability.extra.per))
				ease_dollars(-loss)
				G.GAME.current_round.hands_left = G.GAME.current_round.hands_left + 3
				G.GAME.current_round.discards_left = G.GAME.current_round.discards_left + 3
				return {
					message = "Insurance Bill: " .. tostring(loss),
				}
			end
		end
	},
	{

		key = "anarchist_joker",
		name = "The Anarchist",
		slug = "anarchist_joker",
		sprite = "j_anarchist_joker",
		rarity = 2,
		cost = 8,
		config = { extra = { x_mult = 1 } },
		pos = {
			x = 6,
			y = 0,
		},
		loc_vars = function(self, info_queue, card)
			return {
				vars = {
					card.ability.extra.x_mult,
				},
			}
		end,
		loc_txt = {
			name = "The Anarchist",
			text = {
				"Gain {C:mult}x0.08{} mult when scoring a card that is less than 6,",
				"Lose {C:mult}x0.04{} when scoring higher than 5.",
				"Current Mult: {X:mult,C:white}x#1#{}",
			},
		},
		calculate = function(self, card, context)
			if context.individual and context.cardarea == G.play then
				if context.other_card:get_id() <= 5 then
					play_sound("tarot1")
					card.ability.extra.x_mult = card.ability.extra.x_mult + 0.08
					card:juice_up(0.3, 0.5)
				else
					card.ability.extra.x_mult = card.ability.extra.x_mult - 0.04
					card:juice_up(0.3, 0.5)
				end
			end
			if context.joker_main and context.cardarea == G.jokers and card.ability.extra.x_mult >= 0.01 then
				return {
					Xmult_mod = card.ability.extra.x_mult,
					message = "X" .. tostring(card.ability.extra.x_mult),
				}
			end
		end,
	},
	{

		key = "pol_joker",
		name = "The Politician",
		slug = "pol_joker",
		rarity = 3,
		cost = 10,
		config = {},
		pos = {
			x = 7,
			y = 0,
		},
		loc_txt = {
			name = "The Politician",
			text = { "Destroy the lowest numbered card in your hand", "and create a {C:attention}Golden King{}." },
		},
		sprite = "j_pol_joker",
		calculate = function(self, card, context)
			if context.before then
				local lowest_card = 14
				local lowest_card_index = 0
				for i = 1, #G.hand.cards do
					if G.hand.cards[i]:get_id() < lowest_card then
						lowest_card = G.hand.cards[i]:get_id()
						lowest_card_index = i
					end
				end
				if lowest_card_index > 0 then
					G.hand.cards[lowest_card_index]:shatter()
					local new_card = create_card(
						(pseudorandom(pseudoseed('stdset' .. G.GAME.round_resets.ante)) > 0.6) and "Enhanced" or "Base",
						G.hand, nil, nil, nil, true, nil, 'sta')
					new_card:set_base(G.P_CARDS.S_K)
					new_card:set_ability(G.P_CENTERS.m_gold, nil, true)
					new_card:add_to_deck()
					G.hand:emplace(new_card)
					card:juice_up(0.3, 0.5)
				end
			end
		end,
	},
	{

		key = "wally_joker",
		name = "The Joker In the Wall",
		slug = "wally_joker",
		sprite = "j_wally_joker",
		rarity = 3,
		cost = 9,
		config = { extra = { shatter_next = false, barked = false } },
		pos = {
			x = 8,
			y = 0,
		},
		loc_txt = {
			name = "The Joker In the Wall",
			text = { "Hey Kiddo" },
		},
		loc_vars = function(self, info_queue, card)
			return {
				vars = {
					card.ability.extra.shatter_next,
				},
			}
		end,
		calculate = function(self, card, context)
			if card.ability.extra.barked == false then
				SMODS.Sound.play(nil, 1, 1, false, 'mij_heykiddo')
				card.ability.extra.barked = true
			end
			local messing_with_you = pseudorandom('wfl', 0, 50)
			if context.before and next(context.poker_hands['Pair']) then
				local chance = pseudorandom(pseudoseed('wf'), 1, 8)
				if chance == 8 then
					card:juice_up(0.3, 0.5)
					local effect = joker_wally_effects[math.random(1, #joker_wally_effects)]
					if effect == "misprint" then
						local misprint_1 = create_card('Joker', G.jokers, nil, 1, nil, nil, 'j_misprint')
						local misprint_2 = create_card('Joker', G.jokers, nil, 1, nil, nil, 'j_misprint')
						G.jokers:emplace(misprint_1)
						G.jokers:emplace(misprint_2)
						play_sound("cardFan2")
					end
					if effect == "glass" then
						for i = 1, #G.play.cards do
							G.play.cards[i]:set_ability(G.P_CENTERS.m_glass, nil, true)
							G.play.cards[i]:juice_up(0.3, 0.5)
							play_sound('generic1', 0.9 + math.random() * 0.1, 0.8)
						end
					end
					if effect == "destroy-pair" then
						card.ability.extra.shatter_next = true
					end
					if effect == "negative" then
						local negative_card = G.jokers.cards[math.random(1, #G.jokers.cards)]
						negative_card:set_edition({ negative = true }, true)
					end
				end
			end
			if context.after and context.cardarea == G.jokers and card.ability.extra.shatter_next then
				card:juice_up(0.3, 0.5)
				for i = 1, #G.hand.cards do
					if G.hand.cards[i] ~= nil then
						G.hand.cards[i]:shatter()
					end
				end
				card.ability.extra.shatter_next = false
				SMODS.Sound.play(nil, math.random() / 10 + 0.9, 1, false, 'mij_laugh1')
			end
			if context.end_of_round and messing_with_you >= 50 then
				SMODS.Sound.play(nil, math.random() / 10 + 0.9, 0.25, false, 'mij_laugh2')
			end
		end,
	},
	{

		key = "succ_joker",
		name = "The Succubus",
		slug = "succ_joker",
		loc_txt = {
			name = "The Succubus",
			text = {
				"Converts all the money you earn into mult. ",
				"Lose all gained mult when skipping blinds or boosters",
				"{C:mult}+#1#{} Mult",
			},
		},
		sprite = "j_succ_joker",
		rarity = 4,
		cost = 14,
		config = { extra = { mult = 0 } },
		pos = {
			x = 9,
			y = 0,
		},

		loc_vars = function(self, info_queue, card)
			return {
				vars = {
					card.ability.extra.mult,
				},
			}
		end,
		calculate = function(self, card, context)
			if context.ending_shop then
				card.ability.extra.mult = card.ability.extra.mult + G.GAME.dollars
				ease_dollars(-G.GAME.dollars)
			end
			if context.joker_main and context.cardarea == G.jokers and card.ability.extra.mult >= 1 then
				return {
					mult = card.ability.extra.mult,
				}
			end
			if context.skip_blind or context.skipping_booster then
				card.ability.extra.mult = 0
				return {
					message = joker_succ_messages[math.random(1, #joker_succ_messages)],
				}
			end
		end,
	},
}

for _, joker in ipairs(jokers) do
	SMODS.Joker({
		key = joker.key,
		name = joker.name,
		slug = joker.slug,
		config = joker.config,
		pos = joker.pos,
		rarity = joker.rarity,
		cost = joker.cost,
		blueprint_compat = true,
		eternal_compat = true,
		loc_txt = joker.loc_txt,
		loc_vars = joker.loc_vars,
		sprite = joker.sprite,
		atlas = "mij",
		calculate = joker.calculate,
		calc_dollar_bonus = joker.calc_dollar_bonus,
	})
	sendInfoMessage("Registered: " .. joker.key, "mij")
end


SMODS.Sound:register_global()

sendInfoMessage(inspectDepth(SMODS.Sounds), "mij-wally")

function takePercentage(number, percentage)
	return number * (percentage / 100)
end

function clamp(number, min, max)
	return math.max(min, math.min(max, number))
end

return MOD
