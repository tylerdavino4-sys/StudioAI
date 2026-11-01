// StudioAI backend: local Ollama mode (free, runs on this PC) or optional OpenAI mode.
const http = require("node:http");
const PORT = Number(process.env.STUDIOAI_PORT || 3210);
const PROVIDER = (process.env.STUDIOAI_PROVIDER || "ollama").toLowerCase();
const MODEL = process.env.STUDIOAI_MODEL || (PROVIDER === "ollama" ? "qwen2.5-coder:3b" : "gpt-4.1-mini");
const API_KEY = process.env.OPENAI_API_KEY;

const INSTRUCTIONS = `You are StudioAI, a Roblox Studio game-building assistant.
Return only one valid JSON object: {"message":"short explanation","operations":[...]}.
Do not use markdown or put text outside the JSON object.
Allowed operations:
- create_part: {"type":"create_part","name":"Name","parent":"Workspace","className":"Part","properties":{"Size":[x,y,z],"Position":[x,y,z],"Anchored":true,"CanCollide":true,"Color":[r,g,b],"Material":"SmoothPlastic"}}
- create_folder: {"type":"create_folder","name":"Name","parent":"Workspace"}
- create_script: {"type":"create_script","name":"Name","parent":"ServerScriptService","className":"Script","source":"complete Luau source"}
Allowed part classes: Part, SpawnLocation, WedgePart, CornerWedgePart.
Allowed script classes: Script, LocalScript, ModuleScript.
Allowed parents: Workspace, ServerScriptService, ReplicatedStorage, StarterGui, StarterPack, Lighting.
Maximum 60 operations. Use valid Luau. Never claim changes are already applied.
This version creates new objects only; it cannot safely edit/delete existing objects.
Refuse exploit scripts, credential theft, or cheating in other people's games.
Questions should return an empty operations array.`;

function send(res, status, data) {
  res.writeHead(status, {"Content-Type":"application/json; charset=utf-8","Access-Control-Allow-Origin":"*","Access-Control-Allow-Methods":"GET, POST, OPTIONS","Access-Control-Allow-Headers":"Content-Type"});
  res.end(JSON.stringify(data));
}
function readBody(req) {
  return new Promise((resolve,reject)=>{
    let raw="";
    req.on("data",chunk=>{raw+=chunk;if(raw.length>100000){reject(new Error("Request too large"));req.destroy();}});
    req.on("end",()=>{try{resolve(JSON.parse(raw||"{}"));}catch{reject(new Error("Invalid JSON"));}});
    req.on("error",reject);
  });
}
async function askOllama(input) {
  const response = await fetch("http://127.0.0.1:11434/api/chat", {
    method:"POST", headers:{"Content-Type":"application/json"},
    body:JSON.stringify({model:MODEL,stream:false,format:"json",messages:[
      {role:"system",content:INSTRUCTIONS},
      {role:"user",content:input}
    ]})
  });
  const data = await response.json().catch(()=>({}));
  if (!response.ok) throw new Error(data.error || "Ollama request failed. Is Ollama running?");
  return data.message?.content || "";
}
async function askOpenAI(input) {
  if (!API_KEY) throw new Error("OpenAI API key is missing. Use START_STUDIOAI.bat or switch to the free local launcher.");
  const response=await fetch("https://api.openai.com/v1/responses",{
    method:"POST",headers:{"Authorization":"Bearer "+API_KEY,"Content-Type":"application/json"},
    body:JSON.stringify({model:MODEL,instructions:INSTRUCTIONS,input,text:{format:{type:"json_object"}},max_output_tokens:7000})
  });
  const data=await response.json().catch(()=>({}));
  if(!response.ok) throw new Error(data.error?.message || "OpenAI request failed");
  if(typeof data.output_text==="string") return data.output_text;
  return (data.output||[]).flatMap(x=>x.content||[]).filter(x=>x.type==="output_text").map(x=>x.text).join("\n");
}
const server=http.createServer(async(req,res)=>{
  if(req.method==="OPTIONS") return send(res,204,{});
  if(req.method==="GET" && req.url==="/health") return send(res,200,{ok:true,service:"StudioAI",provider:PROVIDER,model:MODEL});
  if(req.method!=="POST" || req.url!=="/chat") return send(res,404,{error:"Not found"});
  try {
    const body=await readBody(req);
    const prompt=String(body.prompt||"").trim();
    if(!prompt) return send(res,400,{error:"Please enter a prompt."});
    if(prompt.length>6000) return send(res,400,{error:"Prompt is too long (maximum 6000 characters)."});
    const selection=Array.isArray(body.selection)?body.selection.slice(0,20).map(String):[];
    const input="Return a valid JSON object only. User request: "+prompt+"\nSelected Studio objects (context only): "+(selection.join(", ")||"none");
    const output = PROVIDER === "openai" ? await askOpenAI(input) : await askOllama(input);
    let result; try{result=JSON.parse(output);}catch{return send(res,502,{error:"AI response was not valid JSON. Try asking in a simpler way."});}
    if(typeof result.message!=="string") result.message="Here is the proposed build.";
    if(!Array.isArray(result.operations)) result.operations=[];
    result.operations=result.operations.slice(0,60).filter(x=>x&&["create_part","create_script","create_folder"].includes(x.type));
    return send(res,200,result);
  } catch(err){
    const msg = PROVIDER === "ollama" && /fetch failed|ECONNREFUSED/i.test(err.message)
      ? "Ollama is not running yet. Open Ollama, then run: ollama run qwen2.5-coder:3b"
      : (err.message||"Unexpected backend error");
    return send(res,500,{error:msg});
  }
});
server.listen(PORT,"127.0.0.1",()=>{console.log("StudioAI backend running at http://127.0.0.1:"+PORT);console.log("Provider: "+PROVIDER+" | Model: "+MODEL);console.log("Keep this window open while using StudioAI.");});
