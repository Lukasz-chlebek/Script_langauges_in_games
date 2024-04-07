import json
import discord
import requests
from rasa.utils.endpoints import EndpointConfig

intents = discord.Intents.default()
intents.message_content = True

client = discord.Client(intents=intents)
action_endpoint = EndpointConfig(url="http://localhost:5005/webhooks/rest/webhook")
@client.event
async def on_ready():
    print(f'We have logged in as {client.user}')

@client.event
async def on_message(message):
    if message.author == client.user:
        return

    req = requests.post(
        url=action_endpoint.url,
        data=json.dumps({
            "sender": "test",
            "message": message.content
        }),
        headers={"content-type": "application/json"},
        timeout=10)
    response = req.json()[0]["text"]

    await message.channel.send(f'{response}')

token = ""
client.run(token)


