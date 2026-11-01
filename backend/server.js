// StudioAI backend: local Ollama mode (free, runs on this PC) or optional OpenAI mode.
const http = require("node:http");
const fs = require("node:fs");
const path = require("node:path");
const FEEDBACK_FILE = path.join(__dirname, "feedback.json");
function readFeedback() { try { const data = JSON.parse(fs.readFileSync(FEEDBACK_FILE, "utf8")); return Array.isArray(data) ? data : []; } catch { return []; } }
function saveFeedback(items) { fs.writeFileSync(FEEDBACK_FILE, JSON.stringify(items.slice(-2000), null, 2), "utf8"); }
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
Allowed root parents: Workspace, ServerScriptService, ReplicatedStorage, StarterGui, StarterPack, Lighting.
You may place new objects inside folders that your earlier operations create. Use full parent paths such as "Workspace.MyObby" or "Workspace.MyObby.Obstacles", never just "MyObby". Create every required folder before creating objects inside it. Create parent folders before child folders. Keep every path rooted at one of the allowed root parents.
Maximum 100 operations. Use valid Luau. Never claim changes are already applied.
BUILD QUALITY — act like a careful level designer and Roblox builder, not a primitive block spammer:
1) PLAN BEFORE OUTPUT: silently decide a coordinate layout, scale, color palette, player route, focal point, and folder hierarchy. Keep a consistent grid and use exact coordinates so pieces align. Avoid overlaps, floating pieces, random rotations, and inconsistent scale. Leave walkable space and clear paths.
2) MODEL DETAIL: create recognizable objects from multiple pieces. For buildings, use foundation, floor, walls, roof, trim, corner pillars, framed windows, doors, steps, interior partitions, furniture, signs, and exterior props as appropriate. For props, add layered shapes and small details. Use varied dimensions and orientations deliberately; never make every object the same size.
3) VISUAL STYLE: choose a coherent palette of 3–5 colors. Combine SmoothPlastic, Metal, Glass, Neon, Concrete, Wood, Slate, and Fabric where appropriate. Use Neon sparingly for accents, Glass for windows, Metal for frames, and warm/cool lighting colors. Use transparency for glass when useful. Create a visually strong focal point and balanced lighting.
4) LAYOUT: make a complete, navigable composition with a central landmark, readable entrances, connected paths, logical spacing, repeated design language, and decorations that reinforce the theme. For interiors, place furniture at believable heights and leave room to walk. Put related pieces into descriptive folders.
5) GAMEPLAY: when the request asks for a game system, create complete Luau scripts that implement the requested loop, not just decorative objects. Include setup/validation, sensible names, comments, and safe server-side authority for rewards/progression. Put server scripts in ServerScriptService; client UI scripts in StarterGui only when needed. If required remotes are used, create them in ReplicatedStorage before scripts that reference them. Never claim a mechanic works unless its script and required objects are included.
6) ROBLOX API ACCURACY: use standard Roblox Luau APIs only. Use task.wait, not wait. This builder currently creates Parts/Folders only, so do not use Model-only APIs such as PivotTo. Do not reference objects by guessed paths; create them first and use exact names. Avoid deprecated APIs.
7) EFFICIENCY: prioritize quality over quantity. For a normal detailed build, use 35–80 operations. Group each model in folders. Create folders before their contents and use full paths such as Workspace.Project.Buildings.Shop. Keep within 100 operations; for bigger requests, build a polished first section and explain what can be added next. Never output dozens of identical plain blocks.
- Allowed visual operation: create_light: {"type":"create_light","name":"Light","parent":"Workspace.Build.Lights","className":"PointLight","properties":{"Brightness":2,"Range":16,"Color":[80,160,255]}}. Allowed light classes: PointLight, SpotLight, SurfaceLight.
- For Parts, you may also set properties.Orientation as [degreesX,degreesY,degreesZ], properties.Shape as "Block", "Ball", or "Cylinder", properties.Reflectance as a number 0–1, and properties.CastShadow as true/false.
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
  if(req.method==="GET" && req.url==="/feedback/summary") {
    const items=readFeedback(); const counts={};
    for(const item of items) counts[item.category]=(counts[item.category]||0)+1;
    const popular=Object.entries(counts).sort((a,b)=>b[1]-a[1]).map(([category,count])=>({category,count}));
    return send(res,200,{total:items.length,popular});
  }
  if(req.method!=="POST" || !["/chat","/repair","/feedback"].includes(req.url)) return send(res,404,{error:"Not found"});
  try {
    const body=await readBody(req);
    if(req.url==="/feedback") {
      const category=String(body.category||"General").trim().slice(0,40);
      const message=String(body.message||"").trim().slice(0,1200);
      if(message.length<5) return send(res,400,{error:"Please write at least 5 characters of feedback."});
      const items=readFeedback();
      items.push({category:category||"General",message,createdAt:new Date().toISOString()});
      saveFeedback(items);
      const count=items.filter(x=>x.category===category).length;
      return send(res,200,{ok:true,message:"Feedback saved on this computer. Thanks for helping improve StudioAI!",category,count});
    }
    if(req.url==="/repair") {
      const failures=Array.isArray(body.failures)?body.failures.slice(0,12):[];
      if(!failures.length) return send(res,400,{error:"No failed changes were provided."});
      const repairPrompt = "Fix these failed Roblox Studio creation operations. Return ONLY JSON with message and operations. Keep the same intended result. Only use create_part, create_folder, create_script. Valid root parents are Workspace, ServerScriptService, ReplicatedStorage, StarterGui, StarterPack, Lighting. Use full folder paths rooted at those services. Do not use unsupported classes or properties. Do not create exploit or credential theft code. Failed operations and exact errors: " + JSON.stringify(failures);
      const output = PROVIDER === "openai" ? await askOpenAI(repairPrompt) : await askOllama(repairPrompt);
      let repaired; try { repaired=JSON.parse(output); } catch { return send(res,502,{error:"Repair response was not valid JSON."}); }
      if(!Array.isArray(repaired.operations)) repaired.operations=[];
      repaired.operations=repaired.operations.slice(0,12).filter(x=>x&&["create_part","create_script","create_folder","create_light"].includes(x.type));
      return send(res,200,{message:typeof repaired.message==="string"?repaired.message:"I corrected the failed changes.",operations:repaired.operations});
    }
    const prompt=String(body.prompt||"").trim();
    if(!prompt) return send(res,400,{error:"Please enter a prompt."});
    if(prompt.length>6000) return send(res,400,{error:"Prompt is too long (maximum 6000 characters)."});
    const selection=Array.isArray(body.selection)?body.selection.slice(0,20).map(String):[];
    const input="Return a valid JSON object only. User request: "+prompt+"\nSelected Studio objects (context only): "+(selection.join(", ")||"none");
    const output = PROVIDER === "openai" ? await askOpenAI(input) : await askOllama(input);
    let result; try{result=JSON.parse(output);}catch{return send(res,502,{error:"AI response was not valid JSON. Try asking in a simpler way."});}
    if(typeof result.message!=="string") result.message="Here is the proposed build.";
    if(!Array.isArray(result.operations)) result.operations=[];
    result.operations=result.operations.slice(0,100).filter(x=>x&&["create_part","create_script","create_folder"].includes(x.type));
    return send(res,200,result);
  } catch(err){
    const msg = PROVIDER === "ollama" && /fetch failed|ECONNREFUSED/i.test(err.message)
      ? "Ollama is not running yet. Open Ollama, then run: ollama run qwen2.5-coder:3b"
      : (err.message||"Unexpected backend error");
    return send(res,500,{error:msg});
  }
});
server.listen(PORT,"127.0.0.1",()=>{console.log("StudioAI backend running at http://127.0.0.1:"+PORT);console.log("Provider: "+PROVIDER+" | Model: "+MODEL);console.log("Keep this window open while using StudioAI.");});
