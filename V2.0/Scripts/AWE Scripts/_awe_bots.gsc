addBotClients()
{
	level.debug = false;

	//Define RCON cvars
	setcvar("sv_target", 100);
	// setcvar("sv_kick", 0);
	// setcvar("sv_clone", 100);
	// setcvar("sv_tele", 100);
	// setcvar("sv_tele_all", 0);
	// setcvar("sv_tele_allies", 0);
	// setcvar("sv_tele_axis", 0);
	// setcvar("sv_teleport_to", 100);
	// setcvar("sv_disable", 0);

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
			
            ////////////////////////////////////////////////////////////////////////////////////
            /////////////////////////// PAUL'S SMART BOTS - V2.0 ///////////////////////////////
            ////////////////////////////////////////////////////////////////////////////////////

            ////////////////////////////////// REFERENCE ///////////////////////////////////////
            // level.variable - Consider this a global variable.
            // variable - Local variable (single scope).
            // prmVariable - indicates parameter to differentiate parameters from local variables.

            ////////////////////////////////// UPDATE LOG //////////////////////////////////////
			// 8-16-2016: I've started refactoring this code in an attempt to fix the segfaults. 
            // TODO: Confirm functionality of teleportation after rebuild.
            // TODO: Check if we need to remove the initial isDefined(self) call. Maybe self is initially not defined until later?

			if (level.debug) iprintln("Starting SmartBots V2.0");

            // Set up variables for later use.
			level.debugBot = 0;
            level.teleporter = 0;
			level.players = getentarray("player", "classname");
            level.counter = 0; // TODO: Document usage
            level.targetedPlayer = 0;

			if (level.debug) iprintln("Finished setting initial variables");

			if (!isDefined(level.players) || level.players.size < 1) return;
            if (!isDefined(self)) return;

			if (level.debug) iprintln("Finished initial if checks");

            // Assign one bot to perform actions / broadcast messages.
			if (!isDefined(level.debugBot))
			{
				for(i = 0; i < level.players.size; i++)
				{
					if (isDefined(level.players[i]) && isBot(level.players[i]))
					{
						level.debugBot = level.players[i];
						break;
					}
				}
			}

			if (level.debug) iprintln("Finished setting up level.debugBot");
		
            if (!isDefined(level.debugBot)) return;
			if (isDefined(self) && !isAlive(self))
            { 
                wait 1;
                continue;
            }

			if (level.debug) iprintln("Starting this for loop");
			
			for(;;)
			{
                // Run call frequently to capture new players.
                level.players = getentarray("player", "classname");
				if (!isDefined(level.players) || level.players.size < 1) return;

				// Reset counter
				level.counter = 0;
				
				// If a target is not set, target the closest enemy
				// The target can be removed by setting the cvar to 64 or higher
				if (isDefined(self) && isDefined(getCvarInt("sv_target")) && getCvarInt("sv_target") > (level.players.size - 1))
				{
                    // First usage of targetedPlayer was here.
					level.targetedPlayer = self getTarget();

                    if (isDefined(level.targetedPlayer))
                    {
                        self targetPlayer(level.targetedPlayer);
                    }

					wait 0.4;
					continue;
				}
				else break;
			}

			wait 1;
		}
	}
}
	
getTarget()
{
	if (level.debug) iprintln("^3DEBUG: Starting getTarget()");

    targetedPlayer = 0;
    closestDistance = 0;

	if (!isDefined(self) || !isAlive(self)) return;

    // Update the global variable
	level.players = getentarray("player", "classname");
	if (!isDefined(level.players) || level.players.size < 1) return;

	for(i = 0; i < level.players.size; i++)
	{
		// Ideally we loop through players and check if we can even attack them. If so,
		// record the distance initially, then compare the distance to get the 'closestDistance'.
		if (canAttack(level.players[i]))
		{
			if (closestDistance == 0)
			{
				targetedPlayer = level.players[i];
				closestDistance = distance(self.origin, targetedPlayer.origin);
			}
			else
			{
				// If current variable is higher than new calculated distance, use the new distance and target a new player.
				if (closestDistance > distance(self.origin, level.players[i].origin))
				{
					targetedPlayer = level.players[i];
					closestDistance = distance(self.origin, targetedPlayer.origin);
				}
			}
		}
	}

	return targetedPlayer;
}

targetPlayer(prmTargetedPlayer)
{
	if (level.debug) iprintln("^3DEBUG: Starting targetPlayer()");

	closestDistance = 0;
	
	if (!isDefined(prmTargetedPlayer))
	{
		if (level.debug) 
		{
			iprintln("^1DEBUG: prmTargetedPlayer parameter is not defined");
			wait 0.5;
		}
		return;
	}
	
	if (!isDefined(self))
	{
		if (level.debug)
		{
			iprintln("^1DEBUG: self is not defined");
			wait 0.5;
		}
		return;
	}

	if (!isDefined(prmTargetedPlayer.sessionstate))
	{
		if (level.debug)
		{
			iprintln("^1DEBUG: targetedplayer sessionstate is not defined");
			wait 0.5;
		}

		return;
	}

	if (canAttack(prmTargetedPlayer))
	{
		if (level.debug)
		{
			iprintln("^3DEBUG: Setting closestDistance");
			wait 0.5;
		}

		closestDistance = distance(self.origin, prmTargetedPlayer.origin);
	}

	if (closestDistance == 0)
	{
		if (level.debug)
		{
			iprintln("^3DEBUG: closestDistance is 0");
			wait 0.5;
		}
	}

    // If the target is not playing, don't bother firing and keep quiet.
	if (prmTargetedPlayer.sessionstate != "playing") 
	{
		if (level.debug)
		{
			iprintln("^3DEBUG: dont bother firing");
			wait 0.5;
		}

		self setweaponslotammo("primary", 0);
		self setweaponslotclipammo("primary", 0);
		return; 
	}
	
    // If the target is playing but is far away, head towards them but don't shoot yet.
	if(canAttack(prmTargetedPlayer) && closestDistance < 100000)
	{
		if (level.debug)
		{
			iprintln("^3DEBUG: aim but don't shoot yet");
			wait 0.5;
		}

		playerAngles = vectortoangles(prmTargetedPlayer.origin - self.origin);
		if (isDefined(playerAngles)) self setplayerangles(playerAngles);
	}

    // Target in range - open fire.
	if(canAttack(prmTargetedPlayer) && closestDistance < 2000)
	{
		playerAngles = vectortoangles(prmTargetedPlayer.origin - self.origin);

		if (isDefined(playerAngles))
		{
			if (level.debug)
			{
				iprintln("^2DEBUG: aiming and opening fire");
				wait 0.5;
			}

			self setplayerangles(playerAngles);
			//self SwitchToWeapon("kar98k_mp");
			//self setweaponslotweapon("primary", "minigun_mp");
			self setweaponslotammo("primary", 125);
			self setweaponslotclipammo("primary", 5);
		}
	}
	else
	{
		// Target is no longer in range - stop firing to reduce noise.
		self setweaponslotammo("primary", 0);
		self setweaponslotclipammo("primary", 0);

		if (level.debug) iprintln("^3BOT LOST AMMO");
	}
}

isBot(prmPlayer)
{
	if (!isDefined(prmPlayer) || !isPlayer(prmPlayer)) { return false; }
	return (prmPlayer.name[0] == "b" && prmPlayer.name[1] == "o" && prmPlayer.name[2] == "t");
}

isDebugBot()
{
	if (isDefined(self) && isDefined(level.debugBot) && (level.debugBot == self)) return true;
	return false;
}

canAttack(prmOtherPlayer)
{
	if (isDefined(self) && isDefined(prmOtherPlayer) && (prmOtherPlayer != self) && self.sessionstate == "playing" 
		&& prmOtherPlayer.sessionstate == "playing" && isAlive(self) && isAlive(prmOtherPlayer))
	{
		return true;
	}

	return false;
}