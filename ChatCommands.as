#include "CommandChatCommon.as";
#include "CommandChatCommands.as";

//See the !test command if you want to make your own command. Search for !test.


//TODO
// mute player command
//Turn all commands into methods to allow other commands to use each other and the ability to take out commands for use in other mods.
//Have an onTick method that runs commands by the amount of delay they requested. i.e a single tick of delay for spawning bots to allow them to be spawned with a blob.
//Clean up AddBot
//Make Setup return a bool value, in case you want to fail the command before it starts.

//!timespeed SPEED

//!permissionlist             for checking security permissions

//!getplayerroles (PLAYERNAME)

//!tagplayer - tag the CPlayer

//!playerlist

//!playerid's

//!kickid
//!banid

//Symbols. For example. @closest @furthest

//A confirmation that lays out the params, and allows you to either ignore it, or type !y or !yes to confirm the command

//Tagging only tags server side, probably do both client and server side.

//New help menu, preferably interactive. Button for all commands you can use, button for each perm level of commands.

//!actor, but don't kill the old blob

//!setheadnum USERNAME HEADNUMBER
//!setsex USERNAME BOY||GIRL

//!killall blobname - Kills all of a single blob

//!radiusmessage {radius} {content

//!tp (insert location) i.e |red spawn| |blue spawn| |void(y9999)| |etc|

//!emptyinventory || !destroyinventory

//!addtoinventory {blob} (amount) (player)

//!getidvec "netid" - Sends to chat where the blob is. The Vector.

//!foreverbunnify "username"
//Saves something in a config that a person is bunnified.
//Any time the user with that username joins, it mutes them and turns them into a bunny
//Note, do not use target_player. Get the username if it is possible, if not possible just put it in the config as is.

//!unbunnify "username"
//Note, do not use target_player. Get the username if it is possible, if not possible just remove it from the config as is.

//!gethoveroverblobid or !gethoverid
//Prints to chat the netid of the thing your mouse is hovering over
//Use commands.

//!blobwithscripts {scripts
//Ex: !blobwithscripts AimFacePos.as !FleshHitEffects.as Eatable.as
//Starting a script with ! removes the script if the blob comes with it.





//IDEAS: 

//Seperate server only and client only command arrays.

//Command that draws NetID of moused over blob.

//Super admin can disable or enable certain commands.

//Blacklisted blobs

//Custom roles.

//Optimizations to not do comparing of player names or netid's if the token is started with @

//Check if the script it already added before adding it again in addscript

//Forcerespawn spawns the player on the ground.

//make sure you can't abuse the lantern code

//If you put a - after the !, the location for your blob is swapped out for mouse position. Effectively spawning things on your mouse. (tping players to your mouse. etc.)
//"!-chest" will spawn a chest on the position of your cursor.


#include "MakeSeed.as";
#include "MakeCrate.as";
#include "MakeScroll.as";
#include "RunnerCommon.as";
#include "FallDamageCommon.as";
#include "KnockedCommon.as";
#include "RunnerTextures.as";

dictionary player_last_sent(); 
bool ChatCommandCoolDown = false; // Enable if you want cooldowns between commands on your server.
uint ChatCommandDelay = 30 * 3; // Cooldown in seconds.

void onInit(CRules@ this)
{
    //onCommand stuff	
    this.addCommandID("clientshowhelp");
    this.addCommandID("commandwithmpos");
    this.addCommandID("scriptlisttoconsole");
	this.addCommandID("allclientshidehelp");
    this.addCommandID("colorlantern");
    this.addCommandID("addscript");
    this.addCommandID("flipmovers");
    //onCommand end

    if (!GUI::isFontLoaded("AveriaSerif-Bold_22"))
	{		
		string AveriaSerif = CFileMatcher("AveriaSerif-Bold.ttf").getFirst();
		GUI::LoadFont("AveriaSerif-Bold_22", AveriaSerif, 22, true);
	}

    if(!isServer())
    {
        return;
    }
    //Stored value init
    ConfigFile cfg();
    if (cfg.loadFile("../Cache/CommandChatConfig.cfg"))
    {
        //Load values
    }
    //Stored value init end

    //Command array init
    array<ICommand@> initcommands();

    this.set("ChatCommands", initcommands);
    //Command array init end

    this.set_s16("gravity_reverse", 1);


    array<ICommand@> _commands = 
    {
        C_Debug(),
        AllMats(),
        WoodStone(),
        StoneWood(),
        Wood(),
        Stones(),
        Gold(),
        Tree(),
        BTree(),
        AllArrows(),
        Arrows(),
        AllBombs(),
        Bombs(),
        SpawnWater(),
        Seed(),
        Crate(),
        Scroll(),
        FishySchool(),
        ChickenFlock(),
        //New commands are below here.
        HideCommands(),
        ShowCommands(),//Help menu
        PlayerCount(),
        LoadMapCommand(),
        SpinEverything(),
        Test(),
        GiveCoin(),
        PrivateMessage(),
        SetTime(),
        Ban(),
        Unban(),
        Kick(),
        Freeze(),
        Teleport(),
        Coin(),
        SetHp(),
        Damage(),
        Kill(),
        Team(),
        PlayerTeam(),
        ChangeName(),
        Morph(),
        AddRobot(),
        ForceRespawn(),
        Give(),
        GetTag(),
        TagThing(),
        HeldBlobNetID(),
        PlayerBlobNetID(),
        PlayerNetID(),
        Announce(),
        Lantern(),
        ChangeGameState(),
        C_AddScript(),
        BlobNameByID(),
        Mute(),
        Unmute(),
        MassBlobSpawn(),
        ReverseGravity(),
        RulesScriptArray(),
        RulesClearScripts(),
        RulesAddScript(),
        RulesRemoveScript(),
        RulesSetGamemode(),
        RulesGamemode(),
        RebuildScripts(),
        CommandCount()//End*/
    };




    //How to add commands in another file.

    array<ICommand@> commands;
    if(!this.get("ChatCommands", commands)){
        error("Failed to get ChatCommands.\nMake sure ChatCommands.as is before anything else that uses it in gamemode.cfg."); return;
    }

    for(u16 i = 0; i < _commands.size(); i++)
    {
        commands.push_back(_commands[i]);
    }

    this.set("ChatCommands", commands);
    
}//End of onInit

void onReload(CRules@ rules)
{
    onInit(rules);
}

void onRestart( CRules@ this )
{
    player_last_sent.deleteAll();
}

void onNewPlayerJoin( CRules@ this, CPlayer@ player )
{
    if(!isServer() || player == null)
    {
        return;
    }

    //Stored value init (onplayerjoin)
    ConfigFile cfg();
    if (cfg.loadFile("../Cache/CommandChatConfig.cfg"))
    {
        bool _hidecom = false;
        
        if(cfg.exists(player.getUsername() + "_hidecom"))
        {
            _hidecom = cfg.read_bool(player.getUsername() + "_hidecom");
        }
        this.set_bool(player.getUsername() + "_hidecom", _hidecom);
    }
    //Stored value init end
}

bool onServerProcessChat(CRules@ this, const string& in _text_in, string& out text_out, CPlayer@ player)
{
	//--------MAKING CUSTOM COMMANDS-------//
	// Inspect the Test command
    // It will show you the basics
    // Inspect the commented out PlayerCount command if you desire a more barebones command. 

	if (player is null)
    {
        error("player was somehow null");
		return true;
    }

    if(this.get_bool(player.getUsername() + "_muted") == true)//is this player muted?
    {
        Nu::sendClientMessage(player, "You are muted, the message was not sent.");
        return false;//Instant nope.
    }

    bool mouse_pos = false;

    Vec2f pos = Vec2f(0,0);
	int team = 255;

    if(_text_in.size() > 1 && _text_in[1] == "@"[0])//If the character after ! is @
    {
        if(player.get_bool("m_pos"))//If mouse_pos is true
        {
            pos = player.get_Vec2f("m_pos_v");//Get the mouse_pos_vec2f
            player.set_bool("m_pos", false);

            mouse_pos = true;
        }
        else//mouse_pos is false
        {
            //Send the command to client to get the mouse pos, then remove this message.
                //The command to client gets mouse pos, then sends a command to the server with it to run onServerProcessChat again. It will also send the message to every client afterwards.
            //Behavior might be weird if any other onServerProcessChat hooks happen before this.


            CBitStream params;
            params.write_string(_text_in);
            this.SendCommand(this.getCommandID("commandwithmpos"), params, player);
        
            text_out = "";
            return false;
        }
    }

    string text_in;
    
    text_in = atFindAndReplace(pos, _text_in, !mouse_pos, true);//Replace any @closeplayer with the closest player name. etc.
    text_out = text_in;

    //Stop if it isn't a command
    if(_text_in[0] != "!"[0])
    {
        return true;
    }

	CBlob@ blob = player.getBlob(); // now, when the code references "blob," it means the player who called the command

	if (blob != null)
	{
        if(!mouse_pos) {
		    pos = blob.getPosition(); // grab player position (x, y)
        }
        team = blob.getTeamNum(); // grab player team number (for i.e. making all flags you spawn be your team's flags)
	}
    
    u8 blob_name_after;
    if(!mouse_pos)//Default (!)
    {
        blob_name_after = 1;
    }
    else//Mouse pos (!@)
    {
        blob_name_after = 2;
    }

    string[]@ tokens = (text_in.substr(blob_name_after, text_in.size())).split(" ");

    ICommand@ command = @null;

    //print("text_in = " + text_in);
    //print("tokens[0].getHash() == " + tokens[0].getHash());


    array<ICommand@> commands;
    if(!this.get("ChatCommands", commands))
    {
        error("Failed to get ChatCommands.");
        return false;
    }
     
    if(!getCommandByTokens(tokens, commands, player, command))
    {
        return !this.get_bool(player.getUsername() + "_hidecom");
    }

    this.set("ChatCommands", commands);

    
    //Spawn anything
    if(command == null)//If this isn't a command.
    {
        if(!sv_test && !getSecurity().checkAccess_Command(player, "admin_color"))//If sv_test is not true and the player does not have admin color and the player isn't numan
        {
            //Inform the player about not having permissions?
            Nu::sendClientMessage(player, "You don't have permissions to spawn a blob. You may of misspelled a command");
            return !this.get_bool(player.getUsername() + "_hidecom");
        }
        
        if(ChatCommandCoolDown)//If ChatCommandCoolDown is true
        {
            u16 lastChatTime;//Make a variable to store the last time this player used a chatcommand successfully
            if(!player_last_sent.get(""+ player.getNetworkID(), lastChatTime))//If the player's last sent command was not found in the dictionary
            {
                lastChatTime = 0;//Set lastChatTime to 0.
            }

            if(getGameTime() < lastChatTime && lastChatTime != 0)//Do the code within if the lastChatTime is more than getGameTime(). (and it isn't equal to 0 i.e never used.)
            {
                float time_left_in_seconds = Maths::Round(float(lastChatTime - getGameTime()) / 30.0f);

                Nu::sendClientMessage(player, "Command is still under cooldown for " + time_left_in_seconds + " Seconds");
                
                return !this.get_bool(player.getUsername() + "_hidecom");
            }
            //Only if getGameTime() is bigger than lastChatTime will commands work.
        }

        if(blob != null || mouse_pos)
        {
            CBlob@ created_blob = server_CreateBlob(tokens[0], team, pos);
            if(created_blob.getName() == "")
            {
                Nu::sendClientMessage(player, "Failed to spawn " + tokens[0] + ". You may of mispelled a command.");
                return !this.get_bool(player.getUsername() + "_hidecom");
            }
            
            player_last_sent.set(""+ player.getNetworkID(), getGameTime() + ChatCommandDelay);//Set the last sent command time with the delay added.
        }

        player_last_sent.set(""+ player.getNetworkID(), getGameTime() + ChatCommandDelay);//Set the last sent command time with the delay added.

        return !this.get_bool(player.getUsername() + "_hidecom");
    }




    if(command == null)
    {
        return !this.get_bool(player.getUsername() + "_hidecom");
    }

    //Confirm that this command can be used
    if(!command.canUseCommand(this, tokens, player, blob))
    {
        return !this.get_bool(player.getUsername() + "_hidecom");
    }

    //Assign needed values

    CPlayer@ target_player;
    CBlob@ target_blob;

    //If the command wants target_player
    if(command.getTargetPlayerSlot() != 0)
    {   //Get target_player.
        if(!getAndAssignTargets(player, tokens, command.getTargetPlayerSlot(), command.getTargetPlayerBlobParam(), target_player, target_blob))
        {
            return false;//Failing to get target_player warrants stopping the command.
        }
    }		


    //Cooldown check.
    if(ChatCommandCoolDown && !getSecurity().checkAccess_Command(player, "admin_color"))
    {
        u16 lastChatTime;//Make a variable to store the last time this player used a chatcommand successfully
        if(!player_last_sent.get(""+ player.getNetworkID(), lastChatTime))//If the player's last sent command was not found in the dictionary
        {
            lastChatTime = 0;//Set lastChatTime to 0.
        }

        if(getGameTime() < lastChatTime && lastChatTime != 0)//Do the code within if the lastChatTime is more than getGameTime(). (and it isn't equal to 0 i.e never used.)
        {
            float time_left_in_seconds = Maths::Round(float(lastChatTime - getGameTime()) / 30.0f);

            Nu::sendClientMessage(player, "Command is still under cooldown for " + time_left_in_seconds + " Seconds");
            
            return !this.get_bool(player.getUsername() + "_hidecom");
        }
        //Only if getGameTime() is bigger than lastChatTime will commands work.
    }

    player_last_sent.set(""+ player.getNetworkID(), getGameTime() + ChatCommandDelay);



    if(command.CommandCode(this, tokens, player, blob, pos, team, target_player, target_blob))
    {
        return !this.get_bool(player.getUsername() + "_hidecom");//If hidecom is true, chat will not be showed. See !hidecommands
    }
    else
    {
        return false;//returning false prevents the message from being sent to chat.
    }

    //return !this.get_bool(player.getUsername() + "_hidecom");

	return true;//Returning true sends message to chat
}

void onCommand( CRules@ this, u8 cmd, CBitStream@ params )
{
    if(cmd == this.getCommandID("clientshowhelp"))//toggles the gui help overlay
    {
		if(!isClient())
		{
			return;
		}
        CPlayer@ local_player = getLocalPlayer();
        if(local_player == null)
        {
            return;
        }

		if(this.get_bool(local_player.getNetworkID() + "_showHelp") == false)
		{
			this.set_bool(local_player.getNetworkID() + "_showHelp", true);
			client_AddToChat("Showing Commands, type !commands to hide", SColor(255, 255, 0, 0));
		}
		else
		{
			this.set_bool(local_player.getNetworkID() + "_showHelp", false);
			client_AddToChat("Hiding help", SColor(255, 255, 0, 0));
		}
	}
    else if(cmd == this.getCommandID("commandwithmpos"))
    {
        if(isClient())//Client only
        {
            CControls@ controls = getControls();
            if(@controls == @null) { Nu::Error("controls were null?"); return; }
            
            CPlayer@ player = getLocalPlayer();
            if(player == null) { Nu::Error("player was null?"); return; }
            
            string text_in;
            if(!params.saferead_string(text_in)) { Nu::Error("text_in was null?"); return; }

            CBitStream param;
            param.write_u16(player.getNetworkID());
            param.write_Vec2f(controls.getMouseWorldPos());
            param.write_string(text_in);
            if(isLocalHost())//If localhost
            {
                /*CBitStream bs;
                bs = param;
                bs.SetBitIndex(param.getBitIndex());
                @params = @bs;*/
                //TODO, turn this into NuLib function.

                CBitStream bs;
                bs = param;
                bs.SetBitIndex(0);
                @params = @bs;
            }
            else
            {
                this.SendCommand(this.getCommandID("commandwithmpos"), param, false);//Send command to server
            }
        }
        if(isServer())//Server only
        {
            u16 player_id;
            if(!params.saferead_u16(player_id)) { Nu::Error("Failed to get player_id"); return; }
        
            CPlayer@ player = getPlayerByNetworkId(player_id);
            if(player == @null) { return; }

            string text_in;
            Vec2f m_pos;
            if(!params.saferead_Vec2f(m_pos)) { Nu::Error(""); return; }
            if(!params.saferead_string(text_in)) { Nu::Error(""); return; }
            
            player.set_Vec2f("m_pos_v", m_pos);
            player.set_bool("m_pos", true);

            if(onServerProcessChat(this, text_in, text_in, player))//Assuming the return is true. as in not muted.
            {
                Nu::sendAllMessage(text_in, SColor(255,0,0,0), false);//TODO, see if messages send to logs. keep consistent with vanilla.
                //print(text_in);
            }
        }
    }
    else if(cmd == this.getCommandID("scriptlisttoconsole"))
    {
        if(!isClient())
        {
            return;
        }
        array<string> script_array = Nu::Rules::getScriptArray();

        print("Client scripts:", SColor(255, 0, 255, 0));
        for(u16 i = 0; i < script_array.size(); i++)
        {
            print("Script " + i + " is " + script_array[i], SColor(255, 255, 0, 0));
        }

        Nu::sendClientMessage(getLocalPlayer(), "The script lists has been put in your console. Press your Home key.");
    }
	else if(cmd == this.getCommandID("allclientshidehelp"))//hides all gui help overlays for all clients
	{
		if(!isClient())
		{
			return;
		}

		CPlayer@ target_player = getLocalPlayer();
		if (target_player != null)
		{
			if(this.get_bool(target_player.getNetworkID() + "_showHelp") == true)
			{
				this.set_bool(target_player.getNetworkID() + "_showHelp", false);
			}
		}
	}
    else if(cmd == this.getCommandID("colorlantern"))
    {
        CBlob@ lantern = getBlobByNetworkID(params.read_u16());
        if(lantern !is null)
        {
            u8 r, g, b;
            r = params.read_u8();
            g = params.read_u8();
            b = params.read_u8();
            SColor color = SColor(255,r,g,b);
            lantern.SetLightColor(color);
        }
    }
    else if(cmd == this.getCommandID("addscript"))
    {
        print("CAUGHT");
        string script_name = params.read_string();
        string target_class = params.read_string();
        u16 target_netid = params.read_u16();


        if(target_class == "map" || target_class == "cmap")
        {
            getMap().AddScript(script_name);
        }
        else if(target_class == "rules" || target_class == "crules")
        {
            Nu::Rules::AddScript(script_name);
        }
        else
        {
            CBlob@ target_blobert = getBlobByNetworkID(target_netid);//I'm not good at naming variables. Apologies to anyone named blobert.
            if(target_blobert == null)
            {
                client_AddToChat("Could not find the blob associated with the NetID", SColor(255, 255, 0, 0));//Color of the text
                return;
            }
            
            if(target_class == "cblob" || target_class == "blob")
            {
                target_blobert.AddScript(script_name);
            }
            else if(target_class == "csprite" || target_class == "sprite")
            {
                CSprite@ target_sprite = target_blobert.getSprite();
                if(target_sprite == null)
                {
                    client_AddToChat("This blob's sprite is null", SColor(255, 255, 0, 0)); return;
                }
                target_sprite.AddScript(script_name);
            }
            else if(target_class == "cbrain" || target_class == "brain")
            {
                CBrain@ target_brain = target_blobert.getBrain();
                if(target_brain == null)
                {
                    client_AddToChat("The blob's brain is null", SColor(255, 255, 0, 0)); return;
                }
                target_brain.AddScript(script_name);
            }
            else if(target_class == "cshape" || target_class == "shape")
            {
                CShape@ target_shape = target_blobert.getShape();
                if(target_shape == null)
                {
                    client_AddToChat("The blob's shape is null", SColor(255, 255, 0, 0)); return;
                }
                target_shape.AddScript(script_name);
            }
        }
    }
    else
    {
        ReverseGravity::onCommand(this, cmd, params);
    }
}

void onTick(CRules@ this)
{
    ReverseGravity::onTick(this);

}

void onRender( CRules@ this )
{
    ReverseGravity::onRender(this);
    
    if(!isClient())
    {
        return;
    }
    
    GUI::SetFont("menu");

    CPlayer@ localplayer = getLocalPlayer();
    if(localplayer == null)
    {
        return;
    }

    s16 gravity_reverse = this.get_s16("gravity_reverse");
    if(gravity_reverse != 0 && Maths::Abs(gravity_reverse) != 1)
	{
        GUI::SetFont("AveriaSerif-Bold_22");
		GUI::DrawTextCentered("Gravity will be flipped in " + Maths::Roundf(float(Maths::Abs(gravity_reverse)) / 30.0f) + " Seconds. Grab loose items and take cover.", Vec2f(getScreenWidth()/2,getScreenHeight()/2 - 220), SColor(200,255,20,20));
        GUI::SetFont("menu");
	}


    if(this.get_bool(localplayer.getNetworkID() + "_showHelp") == false)
    {
        return;
    }
	u8 nextline = 16;
	

    Vec2f drawPos = Vec2f(getScreenWidth() - 350, 0);
    Vec2f drawPos_width = Vec2f(drawPos.x + 346, drawPos.y);
    GUI::DrawText("Commands parameters:\n" + 
	"{} <- Required\n" + 
    "[] <- Optional" +
    "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n" + 
    "Type !commands to close this window"
    ,
    drawPos, drawPos_width, color_black, false, false, true);
        
    GUI::DrawText("                             :No Roles:\n" +
    "!playercount - Tells you the playercount\n" +
    "!givecoin {amount} {player}\n" +
    "-Deducts coin from you to give to another player\n" +
    "!pm {player} {message}\n" + 
    "- Privately spam player of choosing\n" +
    "!changename {charactername} [player]\n" +
    "- To change another's name, you require admin"
    ,
    Vec2f(drawPos.x, drawPos.y - 7 + nextline * 4), drawPos_width, SColor(255, 255, 125, 10), false, false, false);
    
    GUI::DrawText("                             :Moderators:\n" +
    "!ban {player} [minutes] - Defaults to 60 minutes\n" +
    "Warning, this command auto completes names\n" +
    "!unban {player} - Auto complete will not work\n" +
    "!kickp {player}\n" +
    "!freeze {player} - Use again to unfreeze\n" +
    "!team {team} [player] - Blob team\n" +
    "!playerteam {team} [player] - Player team"
    ,
    Vec2f(drawPos.x, drawPos.y + nextline * 11), drawPos_width, SColor(255, 45, 240, 45), false, false, false);
    
    GUI::DrawText("                             :Admins:\n" +
    "!teleport {player} - Teleports you to the player\n" +
    "!teleport {player1} {player2}\n" +
    "- Teleports player1 to player2\n" +
    "!coin {amount} [player] - Coins appear magically\n" +
    "!sethp {amount} [player] - give yourself 9999 life\n" +
    "!damage {amount} [player] - Hurt their feelings\n" + 
    "!kill {player} - Makes players ask, \"why'd i die?\"\n" +
    "!actor {blob} [player]\n" +
    "-This changes what blob the player is controlling\n" +
    "!forcerespawn {player}\n" +
    "- Drags the player back into the living world\n" +
    "!give {blob} [quantity] [player]\n" +
    "- Spawns a blob on a player\n" +
    "Quantity only relevant to quantity-based blobs\n" +
    "!announce {text}\n" +
    "!addbot [on_player] [blob] [team] [name] [exp]\n" +
    "- ex !addbot true archer 1\n" +
    "On you, archer, team 1\n"+
    "exp=difficulty. Choose a value between 0 and 15"
    ,
    Vec2f(drawPos.x, drawPos.y - 5 + nextline * 20), drawPos_width, SColor(255, 25, 25, 215), false, false, false);

    GUI::DrawText("                             :SuperAdmin:\n" +
    "!settime {time} input between 0.0 - 1.0\n" +
    "!spineverything - go ahead, try it\n" +
    "!hidecommands - hide your admin-abuse\n" +
    "!togglefeatures- turns off/on these commands"
    ,
    Vec2f(drawPos.x, drawPos.y - 3 + nextline * 40), drawPos_width, SColor(255, 235, 0, 0), false, false, false);
}


bool onClientProcessChat(CRules@ this, const string& in text_in, string& out text_out, CPlayer@ player)
{
	if (text_in == "!debug" && !isServer())
	{
		// print all blobs
		CBlob@[] all;
		getBlobs(@all);

        print("client debug");
		for (u32 i = 0; i < all.length; i++)
		{
			CBlob@ blob = all[i];
			print("[" + blob.getName() + " " + blob.getNetworkID() + "] ");

			if (blob.getShape() !is null)
			{
				CBlob@[] overlapping;
				if (blob.getOverlapping(@overlapping))
				{
					for (uint i = 0; i < overlapping.length; i++)
					{
						CBlob@ overlap = overlapping[i];
						print("       " + overlap.getName() + " " + overlap.isLadder());
					}
				}
			}
		}
	}

	return true;
}


void onBlobCreated( CRules@ this, CBlob@ blob )
{
    ReverseGravity::onBlobCreated(this, blob);
}






































//Bad code below
namespace ReverseGravity
{
    array<CBlob@> onblobcreated();
    array<u16> onblobcreatedleft();
    //Stupid idea!
    //What to do about just spawed players flying into the sky?

    //Stupid idea!

    void onTick(CRules@ this)
    {
        s16 gravity_reverse = this.get_s16("gravity_reverse");

        if(onblobcreated.size() != 0)
        {
            for(u16 i = 0; i < onblobcreated.size(); i++)
            {
                u16 value = onblobcreatedleft[i];
                CBlob@ blob;

                if(value != 0)
                {
                    value--;
                    onblobcreatedleft[i] = value;
                    continue;
                }
                else
                {
                    @blob = onblobcreated[i];

                    onblobcreatedleft.removeAt(i);
                    onblobcreated.removeAt(i);
                
                    if(gravity_reverse < 0)
                    {
                        CMovement@ blob_movement = blob.getMovement();
                        if(blob_movement != null)
                        {
                            CSprite@ blob_sprite = blob.getSprite();
                            if(blob_sprite != null)
                            {  
                                blob_sprite.RotateByDegrees(180.0f, -blob_sprite.getOffset());
                                if(blob.hasScript("RunnerHead.as"))
                                {
                                    blob.RemoveScript("RunnerHead.as");
                                    blob_sprite.RemoveScript("RunnerHead.as");
                                    blob_sprite.RemoveSpriteLayer("head");
                                }
                                
                                if(blob_movement.hasScript("FaceAimPosition.as"))
                                {
                                    blob_movement.RemoveScript("FaceAimPosition.as");
                                    blob.set_bool("hasFAP", true);
                                }
                            }   
                        }
                    }
                }
            }
        }//OnBlocCreated

        if(isServer())
        {
            if(Maths::Abs(gravity_reverse) != 1)
            {
                gravity_reverse += 1 * (gravity_reverse >= 0 ? -1 : 1);
                this.set_s16("gravity_reverse", gravity_reverse);

                if(Maths::Abs(gravity_reverse) == 1)
                {
                    if(gravity_reverse > 0)//Flip the gravity to negative
                    {
                        gravity_reverse = -1;
                        this.set_s16("gravity_reverse", gravity_reverse);
                    }
                    else//Gravity Flipping to normal
                    {
                        gravity_reverse = 1;
                        this.set_s16("gravity_reverse", gravity_reverse);
                    }
                    
                    CBitStream params;
                    this.SendCommand(this.getCommandID("flipmovers"), params);
                    
                    sv_gravity = sv_gravity * -1;
                }

                if((Maths::Abs(gravity_reverse) - 1) % 30 == 0)
                {
                    this.Sync("gravity_reverse", true);
                }
            }
        }

        if(gravity_reverse < 0)
        {
            array<CBlob@> blobs;
            getBlobs(blobs);
            bool every_3_ticks = false;
            bool every_10_ticks = false;
            
            if(getGameTime() % 3 == 0)
            {
                every_3_ticks = true;
            }
            
            if(getGameTime() % 10 == 0)
            {
                every_10_ticks = true;
            }

            for(u16 i = 0; i < blobs.size(); i++)
            {
                //Jumping upsidown
                RunnerMoveVars@ moveVars;
                if(blobs[i].get("moveVars", @moveVars))
                {
                    ReversedJumpingCode(blobs[i], moveVars);
                }//Jumping upsidown


                if(every_3_ticks)
                {

                    //Inverted facing direction
                    if((blobs[i].getPlayer() != null || blobs[i].getBrain() != null) && blobs[i].get_bool("hasFAP") && !blobs[i].hasTag("dead"))
                    {
                        bool facing = (blobs[i].getAimPos().x >= blobs[i].getPosition().x);
                        
                        blobs[i].SetFacingLeft(facing);

                        // face for all attachments

                        if (blobs[i].hasAttached())
                        {
                            AttachmentPoint@[] aps;
                            if (blobs[i].getAttachmentPoints(@aps))
                            {
                                for (uint i = 0; i < aps.length; i++)
                                {
                                    AttachmentPoint@ ap = aps[i];
                                    if (ap.socket && ap.getOccupied() !is null)
                                    {
                                        ap.getOccupied().SetFacingLeft(facing);
                                    }
                                }
                            }
                        }

                    }//Inverted facing direction


                }
                

                if(every_10_ticks)
                {
                    
                    if(blobs[i].getPosition().y <= 18 && !blobs[i].isInInventory())//Void damage
                    {
                        if(isServer())
                        {
                            blobs[i].server_Hit(blobs[i], Vec2f(0,0), Vec2f(0,0), 0.25f, 0);
                        }
                        if(blobs[i].hasScript("IgnoreDamage.as"))
                        {
                            blobs[i].RemoveScript("IgnoreDamage.as");
                        }
                    }

                    CShape@ blob_shape = blobs[i].getShape();
                    if(blob_shape != null && !blob_shape.isStatic() && blobs[i].getName() == "seed")//Stop seeds
                    {
                        blob_shape.SetStatic(true);
                    }
                }


            }
        }
    }

    void onBlobCreated( CRules@ this, CBlob@ blob )
    {
        if(this.get_s16("gravity_reverse") < 0)
        {
            onblobcreated.push_back(blob);
            onblobcreatedleft.push_back(5);
        }
    }

    void onCommand( CRules@ this, u8 cmd, CBitStream @params )
    {
        if(cmd == this.getCommandID("flipmovers") )
        {
            array<CBlob@> blobs;
            getBlobs(blobs);
            for(u16 i = 0; i < blobs.size(); i++)
            {
                CMovement@ blob_movement = blobs[i].getMovement();
                if(blob_movement != null)
                {
                    CSprite@ blob_sprite = blobs[i].getSprite();
                    if(blob_sprite != null)
                    {   
                        blob_sprite.RotateByDegrees(180.0f, -blob_sprite.getOffset());
                        if(blobs[i].hasScript("RunnerHead.as"))
                        {
                            blobs[i].RemoveScript("RunnerHead.as");
                            blob_sprite.RemoveScript("RunnerHead.as");
                            blob_sprite.RemoveSpriteLayer("head");
                        }

                        if(blob_movement.hasScript("FaceAimPosition.as"))
                        {
                            blob_movement.RemoveScript("FaceAimPosition.as");
                            blobs[i].set_bool("hasFAP", true);
                        }
                        else if(blobs[i].get_bool("hasFAP"))
                        {
                            blob_movement.AddScript("FaceAimPosition.as");
                            blobs[i].set_bool("hasFAP", false);
                            blobs[i].AddScript("RunnerHead.as");
                            blob_sprite.AddScript("RunnerHead.as");
                        }
                    }
                }

                CShape@ blob_shape = blobs[i].getShape();
                if(blob_shape != null && blob_shape.isStatic() && blobs[i].getName() == "seed")
                {
                    blob_shape.SetStatic(false);
                }
            }
        }
    }
    
    void onRender( CRules@ this )
    {   
        
    }

    void ReversedJumpingCode(CBlob@ blob, RunnerMoveVars@ moveVars)
    {
        if (moveVars.jumpFactor > 0.01f && !isKnocked(blob) && !blob.isOnLadder() && !blob.isOnGround())
        {

            if (blob.isOnCeiling())
            {
                moveVars.jumpCount = 0;
            }
            else
            {
                moveVars.jumpCount++;
            }

            if (blob.isKeyPressed(key_down) && blob.getVelocity().y < moveVars.jumpMaxVel) //blob.getVelocity().y > -moveVars.jumpMaxVel)
            {
                moveVars.jumpStart = 0.7f;
                moveVars.jumpMid = 0.2f;
                moveVars.jumpEnd = 0.1f;
                bool crappyjump = false;

                //todo what constitutes a crappy jump? maybe carrying heavy?
                if (crappyjump)
                {
                    moveVars.jumpStart *= 0.79f;
                    moveVars.jumpMid *= 0.69f;
                    moveVars.jumpEnd *= 0.59f;
                }

                Vec2f force = Vec2f(0, 0);
                f32 side = 0.0f;

                if (blob.isFacingLeft() && blob.isKeyPressed(key_left))
                {
                    side = -1.0f;
                }
                else if (!blob.isFacingLeft() && blob.isKeyPressed(key_right))
                {
                    side = 1.0f;
                }

                // jump
                if (moveVars.jumpCount <= 0)
                {
                    force.y += 1.5f;
                }
                else if (moveVars.jumpCount < 3)
                {
                    force.y += moveVars.jumpStart;
                    //force.x += side * moveVars.jumpMid;
                }
                else if (moveVars.jumpCount < 6)
                {
                    force.y += moveVars.jumpMid;
                    //force.x += side * moveVars.jumpEnd;
                }
                else if (moveVars.jumpCount < 8)
                {
                    force.y += moveVars.jumpEnd;
                }

                //if (blob.isOnWall()) {
                //  force.y *= 1.1f;
                //}

                force *= moveVars.jumpFactor * moveVars.overallScale * 60.0f;


                blob.AddForce(force);

                // sound

                /*if (moveVars.jumpCount == 1 && is_client)
                {
                    TileType tile = blob.getMap().getTile(blob.getPosition() + Vec2f(0.0f, blob.getRadius() + 4.0f)).type;

                    if (blob.getMap().isTileGroundStuff(tile))
                    {
                        blob.getSprite().PlayRandomSound("/EarthJump");
                    }
                    else
                    {
                        blob.getSprite().PlayRandomSound("/StoneJump");
                    }
                }*/
            }
        }
    }
}