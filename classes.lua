--
-- SearchItem
--
-- Objeto de retorno para pesquisas.
--
SearchItem = {}
SearchItem.__index = SearchItem

function SearchItem:new(title, url)
    local self = {}
    self.title = title
    self.url = url
    return setmetatable(self, SearchItem)
end

--
-- Episode
--
-- Objeto de retorno para episódios.
--
Episode = {}
Episode.__index = Episode

function Episode:new(number, url)
    local self = {}
    self.title = ''
    self.number = number
    self.url = url
    return setmetatable(self, Episode)
end
