--[[
  * Copyright (C) 2015 Mattias Bengtsson
  *
  * This library is free software; you can redistribute it and/or
  * modify it under the terms of the GNU Lesser General Public License
  * as published by the Free Software Foundation; version 2.1 of
  * the License, or (at your option) any later version.
  *
  * This library is distributed in the hope that it will be useful, but
  * WITHOUT ANY WARRANTY; without even the implied warranty of
  * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
  * Lesser General Public License for more details.
  *
  * You should have received a copy of the GNU Lesser General Public
  * License along with this library; if not, write to the Free Software
  * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
  * 02110-1301 USA
  *
  * Author: Mattias Bengtsson <mattias.jc.bengtsson@gmail.com>
  *
--]]


API_SERVER              = "https://api.twitch.tv/kraken"
STREAM_SERVER           = ""

FLAGS                   = "hls=true&limit=%s&offset=%s"

TWITCH_TOP_GAMES        = "/games/top"
TWITCH_TOP_CHANNELS     = "/channels/top" -- ?
TWITCH_STREAMS          = "/streams"
TWITCH_STREAMS_GAME     = "/streams?game="
TWITCH_STREAMS_FEATURED = "/streams/featured"
TWITCH_STREAM           = "/streams/%s"
TWITCH_STREAM_ACCESS    = "/channels/%s/access_token"

---------------------------
-- Source initialization --
---------------------------

source = {
  id              = "grl-twitch-lua",
  name            = "Twitch.tv",
  description     = "A source for watching Twitch.tv",
  supported_keys  = { "id", "title", "url" },
  supported_media = "video",
  tags            = { "games", "tv", "net:internet" }
}

------------------
-- Source utils --
------------------

function grl_source_browse(media_id)
  if not media_id then
    grl.callback(create_top_games_box(),            -1)
    grl.callback(create_streams_featured_box(), -1)
    grl.callback(create_top_channels_box(),     -1)
    grl.callback()
    return
  end


  if twitch_route(media_id, "TWITCH_STREAMS_FEATURED") then
    return
  end

  if twitch_route(media_id, "TWITCH_TOP_GAMES") then
    return
  end

  if media_id:match(TWITCH_STREAMS_GAME) then
    local game = media_id:match(TWITCH_STREAMS_GAME .. "(.+)")
    if not game then
      grl.callback()
      return
    else
      grl.fetch(API_SERVER
                  .. TWITCH_STREAMS_GAME:format(game)
                  .. "&"
                  .. FLAGS:format(game, count, skip),
                "twitch_streams_cb")
      return
    end
  end

  grl.callback()
end

function twitch_route(media_id, routeName)
  local count = grl.get_options("count")
  local skip  = grl.get_options("skip")
  local route = _G[routeName]

  DEBUG(routeName:lower() .. "_cb")
  if media_id == route then
    grl.fetch(API_SERVER
                .. route
                .. "?"
                .. FLAGS:format(count, skip),
              routeName:lower() .. "_cb")
    return true
  else
    DEBUG("NO MATCH![" .. media_id .. "] [" .. route .. "]")
    return false
  end
end

function twitch_top_games_cb(data)
  local json = {}

  json = grl.lua.json.string_to_table(data)
  if not json or json.stat == "fail" or not json.top then
    grl.callback()
    return
  end

  for index, top in pairs(json.top) do
    local media = create_game_box(top.game)
    if media ~= nil then
      grl.callback(media, -1)
    end
  end

  grl.callback()
end

function twitch_streams_featured_cb(data)
  local json = {}

  json = grl.lua.json.string_to_table(data)
  if not json or json.stat == "fail" or not json.featured then
    grl.callback()
    return
  end

  for index, featured in pairs(json.featured) do
    local media = create_stream_video(featured.stream)
    if media ~= nil then
      grl.callback(media, -1)
    end
  end

  grl.callback()
end

function twitch_streams_cb(data)
  local json = {}

  json = grl.lua.json.string_to_table(data)
  if not json or json.stat == "fail" or not json.streams then
    grl.callback()
    return
  end

  for index, stream in pairs(json.streams) do
    local media = create_stream_video(stream)
    if media ~= nil then
      grl.callback(media, -1)
    end
  end

  grl.callback()
end

-------------
-- Helpers --
-------------


function create_streams_featured_box()
  local media = {}

  media.type  = "box"
  media.id    = TWITCH_STREAMS_FEATURED
  media.title = "Featured Streams"

  return media
end

function create_top_games_box()
  local media = {}

  media.type  = "box"
  media.id    = TWITCH_TOP_GAMES
  media.title = "Top Games"

  return media
end

function create_top_channels_box()
  local media = {}

  media.type  = "box"
  media.id    = TWITCH_TOP_CHANNELS
  media.title = "Top Channels"

  return media
end

function create_game_box(game)
  local media = {}

  media.type      = "box"
  media.id        = "game/" .. game.name
  media.title     = game.name
  media.thumbnail = game.logo.large

  return media
end

function create_stream_box(stream)
  local media = {}

  media.type      = "box"
  media.id        = "stream_box/" .. stream.channel.name
  media.thumbnail = stream.preview.large
  -- media.url    =
  media.title     = stream.channel.display_name
    .. "\n "
    .. stream.channel.status

  return media
end

function create_stream_video(stream)
  local media = {}

  media.type      = "video"
  media.id        = "stream_video/" .. stream.channel.name
  media.thumbnail = stream.preview.large
  -- media.url    =
  media.title     = stream.channel.display_name
    .. "\n "
    .. stream.channel.status

  return media
end

function DEBUG(msg)  
  grl.debug("Twitch: " .. msg)
end


