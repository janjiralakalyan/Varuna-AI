import os
import sys
from dotenv import load_dotenv
from openai import OpenAI

# Force unbuffered output so print statements appear instantly
sys.stdout.reconfigure(encoding='utf-8')

print("[1/3] Loading .env file...", flush=True)
load_dotenv()

api_key = os.getenv("NVIDIA_API_KEY")

if not api_key:
    print("[ERROR] NVIDIA_API_KEY is not defined in .env!", flush=True)
    exit(1)

print(f"[2/3] Found API Key: {api_key[:10]}...{api_key[-4:]}", flush=True)
print("[3/3] Sending request to NVIDIA NIM (meta/llama-3.3-70b-instruct)...", flush=True)

client = OpenAI(
    base_url="https://integrate.api.nvidia.com/v1",
    api_key=api_key,
    timeout=30.0
)

try:
    completion = client.chat.completions.create(
        model="meta/llama-3.3-70b-instruct",
        messages=[
            {"role": "system", "content": "You are a smart AI agricultural assistant."},
            {"role": "user", "content": "Say hello to the farmer and confirm in 2 sentences that your NVIDIA AI agent is working perfectly."}
        ],
        temperature=0.2,
        max_tokens=150
    )

    print("\n" + "="*50, flush=True)
    print("SUCCESS: NVIDIA API IS WORKING!", flush=True)
    print("="*50, flush=True)
    print("\nAI Response:\n", flush=True)
    print(completion.choices[0].message.content, flush=True)
    print("\n" + "="*50, flush=True)

except Exception as e:
    print(f"\n[ERROR] Request failed: {e}", flush=True)
