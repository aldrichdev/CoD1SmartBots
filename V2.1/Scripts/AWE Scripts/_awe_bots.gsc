addBotClients()
{
	level.debug = getCvarInt("sv_debug");

	//Define RCON cvars
	setcvar("sv_target", 100);

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
					self notify("menuresponse", game["menu_team"], "allies");
				else
					self notify("menuresponse", game["menu_team"], "allies");
				wait 0.5;

				if(self.pers["team"]=="axis")
				{
					self notify("menuresponse", game["menu_weapon_axis" + bel], "minigun_mp");
				}
				else
				{
					self notify("menuresponse", game["menu_team"], "allies");
					wait 0.5;

					// Added by Kraken - Weapon Randomization (American Only)
					someInt = randomint(10);

					if(game["allies"] == "russian" || game["allies"] == "american")
					{
						if (someInt >= 4)
						{
							self notify("menuresponse", game["menu_weapon_allies" + bel], "minigun_mp");
						}
						else
						{
							self notify("menuresponse", game["menu_weapon_allies" + bel], "noobtube_mp");
						}
					}
						
					else
					{
						self notify("menuresponse", game["menu_weapon_allies" + bel], "enfield_mp");
					}
				}
			}
			
            /////////////////////////// PAUL'S SMART BOTS - V2.1 ///////////////////////////////

            ////////////////////////////////// REFERENCE ///////////////////////////////////////
            // level.variable - Consider this a global variable.
            // variable - Local variable (single scope).
            // prmVariable - indicates parameter to differentiate parameters from local variables.

            ////////////////////////////////// UPDATE LOG //////////////////////////////////////
			// 8-27-2016: Updated bot logic to only shoot if bullettrace registers a player entity.
			//   Switched bot teams to Allies and added some weapon randomization for Americans.
			// 8-20-2016: Refactored code. Removed some features to test functionality.
            // TODO: Confirm functionality of teleportation after rebuild.
            // TODO: Check if we need to remove the initial isDefined(self) call. Maybe self is initially not defined until later?

			if (level.debug) iprintln("Starting SmartBots V2.1");

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
					level.targetedPlayer = self getTarget();

					// player.name will be undefined if they are in spec sometimes.
                    if (isDefined(level.targetedPlayer) && isDefined(level.targetedPlayer.name))
                    {
                        self targetPlayer(level.targetedPlayer);
                    }
					else
					{
						botDisable(self);
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
	
	if (!isDefined(self))
	{
		if (level.debug)
		{
			iprintln("^1DEBUG: self is not defined");
			//wait 0.5;
		}
		return;
	}

	if (canAttack(prmTargetedPlayer))
	{
		if (level.debug)
		{
			iprintln("^3DEBUG: Setting closestDistance");
			//wait 0.5;
		}

		closestDistance = distance(self.origin, prmTargetedPlayer.origin);
	}

	if (closestDistance == 0)
	{
		if (level.debug)
		{
			iprintln("^3DEBUG: closestDistance is 0");
			//wait 0.5;
		}
	}

    // If the target is not playing, don't bother firing and keep quiet.
	if (prmTargetedPlayer.sessionstate != "playing") 
	{
		if (level.debug)
		{
			iprintln("^3DEBUG: dont bother firing");
			//wait 0.5;
		}

		botDisable(self);
		return; 
	}
	
    // If the target is playing but is far away, head towards them but don't shoot yet.
	if(canAttack(prmTargetedPlayer) && closestDistance < 100000)
	{
		if (level.debug)
		{
			iprintln("^3DEBUG: aim but don't shoot yet");
			//wait 0.5;
		}

		playerAngles = vectortoangles(prmTargetedPlayer.origin - self.origin);
		if (isDefined(playerAngles)) self setplayerangles(playerAngles);
	}

    // Target in range - open fire.
	if(canAttack(prmTargetedPlayer) && isClearShot(self, prmTargetedPlayer) && closestDistance < 5000)
	{
		playerAngles = vectortoangles(prmTargetedPlayer.origin - self.origin);

		if (isDefined(playerAngles))
		{
			if (level.debug)
			{
				iprintln("^2DEBUG: aiming and opening fire");
				//wait 0.5;
			}

			// REMEMBER: If the bot is allowed to use AWE sprinting this will not work!
			// Disable AWE sprinting in _awe.gsc (for bots only) and you should be set.
			self setplayerangles(playerAngles);
			self setweaponslotammo("primary", 900);
			self setweaponslotclipammo("primary", 300);
		}
	}
	else
	{
		botDisable(self);
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

isClearShot(prmSelf, prmTarget)
{
	// Premise: Use bullettrace() to fire a fake bullet and see if there is any interference between self and target.
	// If so, and it is NOT the target, return false to stop the bot from firing.

	// Check if parameters are defined. If not, return true (allow the bot to fire).
	if (!isDefined(prmSelf) || !isDefined(prmTarget))
	{
		if (level.debug)
		{
			iprintln("^1DEBUG: Self and/or target not defined. Bot will shoot regardless.");
		}
		return true;
	}

	/* Get the trace
	USAGE:  bullettrace(start, end, hit_players, entity_to_ignore) */
	trace = bullettrace(self.origin, prmTarget.origin, true, undefined);

	if (!isDefined(trace))
	{
		if (level.debug)
		{
			iprintln("^1DEBUG: Trace not defined");
		}
		return true;
	}

	if (isDefined(trace["fraction"]) && trace["fraction"] == 1)
	{
		// Bullet did not hit anything
		return true;
	}

	if(isDefined(trace["entity"]) && isPlayer(trace["entity"]))
	{
		// Clear to shoot..
		return true;
	}

	// NOTE: These surfacetype checks seem to be useless since the surface is always default
	if (isDefined(trace["surfaceType"]) && (trace["surfacetype"] == "flesh" || 
		trace["surfacetype"] == "foliage") || trace["surfacetype"] == "bark")
	{
		// This will need to be tweaked, but for now I'm okay with these surfaces.
		return true;
	}

	if (level.debug)
	{
		iprintln("^3DEBUG: Bot hit an invalid surface, is NOT clear to shoot.");
		if (isDefined(trace["surfaceType"]))
		{
			iprintln("^3DEBUG: Surface Type: '^5" + trace["surfaceType"] + "^7'");
		}
	}
	return false;
}

botDisable(prmBot)
{
	prmBot setweaponslotammo("primary", 0);
	prmBot setweaponslotclipammo("primary", 0);

	if (level.debug) iprintln("^3BOT LOST AMMO");
}