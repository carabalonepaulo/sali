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
    for url, title in r:gmatch(pattern) do table.insert(list, { title = title, url = url }) end
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
function SuperAnimes:getepisodelist(url)
    if url:sub(-1, -1) == '/' then url = url:sub(0, -2) end
    local r, c = http.request(url)
    local name = url:match('http://www.superanimes.com/([^/]+)/?')
    local episodes = r:match('numberofEpisodes">(%d+)<')
    local list = {}
    for i = 1, episodes do table.insert(list, { number = i, url = url..'/episodio-'..i }) end
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
    r, c = http.request {
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
    return resp:match('<source src="(.+)" type=')
end

-- instancia o obeto de abstração do site
local salayer = SuperAnimes:new()
-- pesquisa por "naruto"
local result = salayer:search('naruto')
-- obtém a lista de episódios do primeiro resultado da busca
local episodes = salayer:getepisodelist(result[1].url)
-- obtém a url direta do primeiro episódio do anime
local videourl = getvideourl(episodes[1].url)
