import Config

config :nostrum,
  token: System.get_env("DISCORD_TOKEN"),
  gateway_intents: [
    :guilds,
    :guild_members,
    :guild_messages,
    :guild_message_reactions,
    :direct_messages,
    :direct_message_reactions,
    :message_content
  ]

config :logger,
  backends: [:console, {LoggerFileBackend, :log}]

config :logger, :log, 
  path: "/tmp/perudexcord_logs.log",
  level: :notice
