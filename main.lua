require 'classes'
local http = require 'socket.http'
local ltn12 = require 'ltn12'

local SuperAnimes = {}
SuperAnimes.__index = SuperAnimes

--
-- new
--
-- Método construtor
--
-- @return  table
--
function SuperAnimes:new()
    return setmetatable({}, SuperAnimes)
end

--
-- search
--
-- Busca por animes que contenham o termo.
--
-- @param   name    Termo de busca
-- @return  table
--
function SuperAnimes:search(name)
    local r, c = http.request('http://www.superanimes.com/anime?&letra='..name)
    local list = {}
    local pattern = '<a href="(http://www.superanimes.com/[^/]+)" title="([^"]+)"><h2>'
    for url, title in r:gmatch(pattern) do table.insert(list, SearchItem:new(title, url)) end
    return list
end

--
-- getepisodelist
--
-- Obtém a lista de episódios a partir da url.
--
-- @param   url     URL do anime
-- @return  table
--
function SuperAnimes:getepisodelist(url, page)
    if url:sub(-1, -1) == '/' then url = url:sub(0, -2) end
    local r, c = http.request(url..'?&pagina='..page)
    local name = url:match('http://www.superanimes.com/([^/]+)/?')
    local list, count = {}, 1
    for i in r:gmatch('<h3 itemprop="name">([^>]+)</h3>') do
        table.insert(list, Episode:new(count, i, url..'/episodio-'..count))
        count = count + 1
    end
    return list
end

--
-- getvideourl
--
-- Obtém a URL do vídeo a partir da URL do episódio. Devido ao método
-- utilizado pelo site para evitar que os episódios fossem obtidos por bots
-- o código acabou por ficar um pouco extenso.
--
-- @param   episodeurl  URL do episódio
-- @return  string
--
function SuperAnimes:getvideourl(episodeurl)
    local url = 'http://www.superanimes.com/inc/stream.inc.php'
    local r, c = http.request(episodeurl)
    local payload = r:match('(id=[a-zA-Z0-9=-]+&tipo=[a-zA-Z0-9=-]+)')
    local response = {}
    local rec = http.request {
        url = url,
        method = 'POST',
        source = ltn12.source.string(payload),
        headers = {
            ['Content-Type'] = 'application/x-www-form-urlencoded',
            ['Content-Length'] = payload:len()
        },
        sink = ltn12.sink.table(response)
    }
    local resp = table.concat(response)
    local video = resp:match('<source src="(.+)" type=')
    if video:match('superanimes') then
        local r, c, h = http.request { method = 'HEAD', url = video }
        return h['location'] or video
    else return video end
end

-- instancia o obeto de abstração do site
local layer = SuperAnimes:new()
-- pesquisa por "naruto"
local result = layer:search('naruto')
-- obtém a lista de episódios do primeiro resultado da busca
local episodes = layer:getepisodelist(result[1].url, 1)
-- obtém a url direta do primeiro episódio do anime
local videourl = layer:getvideourl(episodes[1].url)