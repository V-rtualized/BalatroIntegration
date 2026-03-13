BInt._resolve = {}

local RANK_MAP = {
    A = "Ace", ["2"] = "2", ["3"] = "3", ["4"] = "4", ["5"] = "5",
    ["6"] = "6", ["7"] = "7", ["8"] = "8", ["9"] = "9", ["10"] = "10",
    J = "Jack", Q = "Queen", K = "King"
}
BInt._resolve.RANK_MAP = RANK_MAP

local SUIT_MAP = {
    s = "Spades", h = "Hearts", d = "Diamonds", c = "Clubs"
}
BInt._resolve.SUIT_MAP = SUIT_MAP

local RANK_TO_SHORT = {}
for k, v in pairs(RANK_MAP) do RANK_TO_SHORT[v] = k end

local SUIT_TO_SHORT = {}
for k, v in pairs(SUIT_MAP) do SUIT_TO_SHORT[v] = k end

function BInt._resolve.parse_card_id(id)
    local rank_str, suit_char
    if #id == 2 then
        rank_str = id:sub(1, 1)
        suit_char = id:sub(2, 2)
    elseif #id == 3 then
        rank_str = id:sub(1, 2)
        suit_char = id:sub(3, 3)
    end
    local rank = RANK_MAP[rank_str]
    local suit = SUIT_MAP[suit_char]
    if not rank or not suit then
        return nil, "invalid_card_id"
    end
    return { rank = rank, suit = suit }
end

function BInt._resolve.card_to_id(card)
    local rank = RANK_TO_SHORT[card.base.value] or card.base.value
    local suit = SUIT_TO_SHORT[card.base.suit] or card.base.suit:sub(1, 1):lower()
    return rank .. suit
end

function BInt._resolve.in_area(area, id_or_index, key_fn)
    if not area or not area.cards then return nil, "area_not_found" end
    if type(id_or_index) == "number" then
        local card = area.cards[id_or_index]
        if card then return card end
        return nil, "index_out_of_range"
    end
    for _, card in ipairs(area.cards) do
        if key_fn(card) == id_or_index then
            return card
        end
    end
    return nil, "key_not_found"
end

function BInt._resolve.hand_card(id_or_index)
    return BInt._resolve.in_area(G.hand, id_or_index, function(card)
        return BInt._resolve.card_to_id(card)
    end)
end

function BInt._resolve.joker(id_or_index)
    return BInt._resolve.in_area(G.jokers, id_or_index, function(card)
        return card.config.center.key
    end)
end

function BInt._resolve.consumable(id_or_index)
    return BInt._resolve.in_area(G.consumeables, id_or_index, function(card)
        return card.config.center.key
    end)
end

function BInt._resolve.shop_card(id_or_index)
    return BInt._resolve.in_area(G.shop_jokers, id_or_index, function(card)
        return card.config.center.key
    end)
end

function BInt._resolve.shop_voucher(id_or_index)
    return BInt._resolve.in_area(G.shop_vouchers, id_or_index, function(card)
        return card.config.center.key
    end)
end

function BInt._resolve.shop_pack(id_or_index)
    return BInt._resolve.in_area(G.shop_booster, id_or_index, function(card)
        return card.config.center.key
    end)
end

function BInt._resolve.pack_card(id_or_index)
    return BInt._resolve.in_area(G.pack_cards, id_or_index, function(card)
        if card.ability.set == 'Default' or card.ability.set == 'Enhanced' then
            return BInt._resolve.card_to_id(card)
        else
            return card.config.center.key
        end
    end)
end
