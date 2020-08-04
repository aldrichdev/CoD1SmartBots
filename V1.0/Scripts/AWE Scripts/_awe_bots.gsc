addBotClients()
{
	//Define RCON cvars
	setcvar("sv_target", 100);
	setcvar("sv_kick", 0);
	setcvar("sv_clone", 100);
	setcvar("sv_tele", 100);
	setcvar("sv_tele_all", 0);
	setcvar("sv_tele_allies", 0);
	setcvar("sv_tele_axis", 0);
	setcvar("sv_teleport_to", 100);
	setcvar("sv_disable", 0);

	level endon("awe_boot");

	wait 2;

	if(level.awe_debug)
		iprintln(level.awe_allplayers.size + " players found.");

	numbots = 0;
	// Catch & count running bots and start their think threads.
	for(i=0;i<level.awe_allplayers.size;i++)
	{
		if(isdefined(level.awe_allplayers[i]))
		{
			player = level.awe_allplayers[i];
			if(player.name.size==4 || player.name.size==5)
			{
				if(player.name[0] == "b" && player.name[1] == "o" && player.name[2] == "t")
				{
					player thread bot_think();
					numbots++;
				}
			}
		}
	}
	
	for(;;)
	{
		wait 3;

		// Any new bots to add?
		newbots = level.awe_bots - numbots;
	
		// Any new bots to add?
		if(newbots<=0)
			continue;

		for(i = 0; i < newbots; i++)
		{
			bot = addtestclient();
			wait 0.5;
			if(isdefined(bot) && isPlayer(bot))
				bot thread bot_think();
			numbots++;
		}
	}
}

bot_think()
{
	level endon("awe_boot");

	if(level.awe_debug)
		iprintln("Starting think thread for: " + self.name);

	if(getcvar("g_gametype") == "bel" || getcvar("g_gametype") == "mc_bel")
		bel = "_only";
	else
		bel = "";

	if(isPlayer(self))
	{
		for(;;)
		{
			if(!isAlive(self) && self.sessionstate != "playing")
			{
				if(level.awe_debug)
					iprintln(self.name + " is sending menu responses.");

				if(bel == "")
					self notify("menuresponse", game["menu_team"], "autoassign");
				else
					self notify("menuresponse", game["menu_team"], "axis");
				wait 0.5;	

				if(self.pers["team"]=="axis")
				{
					self notify("menuresponse", game["menu_weapon_axis" + bel], "kar98k_mp");
				}
				else
				{
					self notify("menuresponse", game["menu_team"], "allies");
					wait 0.5;
					if(game["allies"] == "russian" || game["allies"] == "american")
						self notify("menuresponse", game["menu_weapon_allies" + bel], "mosin_nagant_mp");
					else
						self notify("menuresponse", game["menu_weapon_allies" + bel], "enfield_mp");
				}
			}
			
			//-----------------Added by Paul---------------//
			
			players = getentarray("player", "classname");
			
			//Default Values
			targetedPlayer = players[0];
			closestDistance = distance(self.origin, targetedPlayer.origin);
			
			//Only have one bot perform actions/broadcast messages:
			level.debugBot = players[1];
			if (isBot(players[1])) { level.debugBot = players[1]; }
			else if(isBot(players[2])) { level.debugBot = players[2]; }
			else if(isBot(players[3])) { level.debugBot = players[3]; }
		
			if (!isAlive(self)) { wait 0.05; continue; }
			
			counter = 0;
			
			for(;;)
			{
				players = getentarray("player", "classname");
				
				//Find Teleporter
				for(i = 0; i < players.size; i++)
				{
					if (!isDefined(players[i])) continue;
					if (players[i].name == "Teleporter")
					{
						teleporter = players[i];
						break;
					}
				}
				
				//Log players as CVARs so they can be teleported
				for(i = 0; i < players.size; i++)
				{
					if (!isDefined(players[i])) continue;
					nameOfPlayer = players[i].name;
					if (IsDefined(getCvarInt(nameOfPlayer)))
					{
						if (getCvarInt(nameOfPlayer) < (players.size - 1) && self == level.debugBot) 
						{
							players[i] setorigin(players[getCvarInt(nameOfPlayer)].origin);
							setcvar(nameOfPlayer, 100);
						}
					}
					else setcvar(nameOfPlayer, 100); 
				}
				
				//Clone the player that the cvar is set to:
				if (getCvarInt("sv_clone") <= (players.size - 1))
				{
					players[getCvarInt("sv_clone")] cloneplayer();
				}
				
				//Teleport One Bot (or Player) To Teleporter:
				if (getCvarInt("sv_tele") <= (players.size - 1))
				{
					if (self == level.debugBot)
					{
						if (isDefined(teleporter))
						{
							players[getCvarInt("sv_tele")] setorigin(teleporter.origin);
							setcvar("sv_tele", 100); //Only teleport once...
						}
					}
				}
				
				//Teleport all Allied bots to Teleporter
				if (getCvarInt("sv_tele_allies") == 1)
				{
					if (isDefined(teleporter) && isDefined(self))
					{
						team = "allies";
						self teleportTeamBots(teleporter, team);
					}
				}
				
				//Teleport all Axis bots to Teleporter
				if (getCvarInt("sv_tele_axis") == 1)
				{
					if (isDefined(teleporter) && isDefined(self))
					{
						team = "axis";
						self teleportTeamBots(teleporter, team);
					}
				}
				
				//Set this cvar to 1 to teleport ALL bots to Teleporter (Chaos...):
				if (getCvarInt("sv_tele_all") == 1) 
				{
					if (isDefined(teleporter))
					{
						teleportAllBots(teleporter);
					}
				}
				
				//Disable bots (prevent them from aiming/shooting)
				if (getCvarInt("sv_disable") > 0)
				{
					if (!isDefined(self))
					{
						iprintln("A bot (self) was not defined - return; (No disabling.)");
						return;
					}
					self setweaponslotammo("primary", 0);
					self setweaponslotclipammo("primary", 0);
					if (self == level.debugBot && counter == 0) iprintln("^3Bots temporarily disabled");
					counter = counter + 1;
					wait 2;
					continue;
				}
				
				//reset counter
				counter = 0;
				
				//If a target is not set, target the closest enemy
				//The target can be removed by setting the cvar to 64 or higher
				if (getCvarInt("sv_target") > (players.size - 1))
				{
					if (!isDefined(self)) 
					{
						iprintln("A bot (self) was not defined - return (No normal targeting.)");
						return;
					}
					targetedPlayer = self getTarget();
					self targetPlayer(targetedPlayer);
					wait 0.4;
					continue;
				}
				else break;
			}

			//iprintln("---FINISHED INNER LOOP---");
			
			//When sv_target is set to a player:
			clientNumber = getCvarInt("sv_target");
			
			if (self == level.debugBot)
			{
				iprintln("Uh-oh.... " + players[clientNumber].name + "^3 is the new target!");
				iprintlnbold(players[clientNumber].name + " is entering ^1SURVIVOR MODE!");
				iprintln(players[clientNumber].name + " ^3has been given unlimited primary gun ammo");
			}
			
			for(i = 0; i < players.size; i++)
			{
				if (i == getCvarInt("sv_target"))
				{
					if (!isDefined(players[i])) continue;
					targetedPlayer = players[i];
					break;
				}
			}
			
			while (getCvarInt("sv_target") == clientNumber)
			{
				//Keep targeting the player until the cvar changes.
				if (!isDefined(targetedPlayer) || !isDefined(self)) break;
				closestDistance = distance(self.origin, targetedPlayer.origin);
				self targetPlayer(targetedPlayer, closestDistance);
				targetedPlayer setweaponslotammo("primary", 300);
				targetedPlayer setweaponslotclipammo("primary", 30);
				wait 0.2;
			}
			
			if (self == level.debugBot)
			{
				iprintln("Player " + players[clientNumber].name + "^2 is no longer targeted! ^3(Ammo reset)");
				iprintlnbold("^2Free for all!");
			}
			
			wait 1; //10

			//iprintln("---FINISHED OUTER LOOP---");
		}
	}
}
	
getTarget()
{
	if (!isDefined(self))
	{
		//iprintln("self is not defined");
		return;
	}
	if (!isAlive(self)) 
	{
		return;
	}

	
	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
	{
		if (players[0] != self && players[0].sessionstate == "playing" 
		&& isNotMyTeam(players[0]))
		{
			targetedPlayer = players[0];
			// if (isDefined(targetedPlayer)) 
			// {
			// 	iprintln("My name is " + self + " and I am targeting " + targetedPlayer);
			// }
			closestDistance = distance(self.origin, players[0].origin);
		}
		else if (players[1] != self && players[1].sessionstate == "playing" 
		&& isNotMyTeam(players[1]))
		{
			targetedPlayer = players[1];
			// if (isDefined(targetedPlayer)) 
			// {
			// 	iprintln("My name is " + self + " and I am targeting " + targetedPlayer);
			// }
			closestDistance = distance(self.origin, players[1].origin);
		}
		for(i = 1; i < players.size; i++)
		{
			if (!isDefined(players[i])) continue;
			dist = distance(self.origin, players[i].origin);
			if (players[i] != self && players[i].sessionstate == "playing" 
			&& isNotMyTeam(players[i]) && closestDistance > dist)
			{
				targetedPlayer =  players[i];
				// if (isDefined(targetedPlayer))
				// {
				// 	iprintln("My name is " + self + " and I am targeting " + targetedPlayer + " in inner for loop");
				// }
				closestDistance = distance(self.origin, targetedPlayer.origin);
			}
		}
	}
	
	// if (isDefined(targetedPlayer))
	// {
	// 	iprintln("End of getTarget(): targetedPlayer IS DEFINED YAY");
	// }
	// else
	// {
	// 	iprintln("End of getTarget(): targetedPlayer IS NOT DEFINED BOOHOO");
	// }
	return targetedPlayer;
}

targetPlayer(targetedPlayer)
{
	if (!isDefined(self))
	{
		return;
	}
	if (!isDefined(targetedPlayer) && isDefined(level.debugBot) && self == level.debugBot)
	{
		iprintln("My name is " + level.debugBot + ". In targetPlayer() function - targetedPlayer was not defined");
		return;
	}
	
	closestDistance = distance(self.origin, targetedPlayer.origin);
	if (targetedPlayer.sessionstate != "playing") 
	{
		self setweaponslotammo("primary", 0);
		self setweaponslotclipammo("primary", 0);
		return; 
	}
	
	if(targetedPlayer.sessionstate == "playing" && targetedPlayer != self && closestDistance < 100000
	&& isNotMyTeam(targetedPlayer))
	{
		//Go towards the closest player.
		playerAngles = vectortoangles(targetedPlayer.origin - self.origin);
		self setplayerangles(playerAngles);
	}
	if(targetedPlayer.sessionstate == "playing" && targetedPlayer != self && closestDistance < 2000
	&& isNotMyTeam(targetedPlayer))
	{
		playerAngles = vectortoangles(targetedPlayer.origin - self.origin);
		self setplayerangles(playerAngles);
		self setweaponslotammo("primary", 125);
		self setweaponslotclipammo("primary", 5);
	}
	else
	{
		self setweaponslotammo("primary", 0);
		self setweaponslotclipammo("primary", 0);
	}
}

isBot(player)
{
	if (!isPlayer(player)) { return false; }
	return (player.name[0] == "b" && player.name[1] == "o" && player.name[2] == "t");
}

isTeamGame()
{
	if (level.awe_gametype == "dm") return false;
	else return true;
}

isNotMyTeam(player)
{
	myTeam = self.pers["team"];
	if (isTeamGame())
	{
		if (player.pers["team"] != myTeam) return true;
		else return false;
	}
	else return true;
}	

isPaul(player)
{
	if(player.name == "Stunt//Paul")
	{
		return true;
	}
	else return false;
}

teleportAllBots(teleporter)
{
	players = getentarray("player", "classname");
	
	for(i = 0; i < players.size; i++)
	{
		if (!isDefined(players[i])) continue;
		if (self == level.debugBot && isBot(players[i]))
		{
			players[i] setorigin(teleporter.origin);
			if (players[i] == players[(players.size - 1)]) //Last bot?
			{
				setcvar("sv_tele_all", 0);
				break;
			}
		}
	}
}

teleportTeamBots(teleporter, team)
{
	players = getentarray("player", "classname");
	
	for(i = 0; i < players.size; i++)
	{
		if (!isDefined(players[i])) continue;
		if (self == level.debugBot && isBot(players[i]) && players[i].pers["team"] == team)
		{
			players[i] setorigin(teleporter.origin);
		}
	}
	
	//Don't teleport bots more than once:
	if (self == level.debugBot) setcvar("sv_tele_" + team, 0);
}

kickBots()
{
	// players = getEntArray("player", "classname");
	
	// for(i = 0; i < players.size; i++)
	// {
		// if (isBot(players[i]))
			// kick(players[i] getEntityNumber(), "EXE_PLAYERKICKED");
	// }
}

//Comment Code//
					//iprintln("Debug bot active= " + level.debugBot.name);
					//iprintln("Cvar is set to <= " + (players.size - 1));
					//Teleport bot to Paul (if he exists)
					//botToTeleport = getCvarInt("sv_tele");
					//iprintln("I am " + self.name + "and I am also " + players[getCvarInt("sv_tele")]);

						//iprintln("allare good- self is debug. cvar is " + getCvarInt("sv_tele"));
						
							//iprintlnbold("If you can read this, " + players[getCvarInt("sv_tele")]
						// + " was teleported to " + teleporter.name);
						
//iprintln(players[(players.size - 1)].name + " will be checked against players[i] (last bot?)");

							//iprintln("teleporting to stunt//paul:" + players[i].name);
							
							//iprintln("players[i] is " + players[i].name);
		//iprintln("To Continue - self: " + self.name + " must be also " + level.debugBot + ", " + players[i].name + " must be a bot, and " + players[i].pers["team"] + " must be " + team);
		
		//iprintln("players[i] is a bot; players[i] team = " + players[i].pers["team"] + "which is also " + team);
		
					// if (getCvarInt("sv_clone") >  0 && self.name == "bot0")
			// {
				// self cloneplayer();
			// }
			
			
		