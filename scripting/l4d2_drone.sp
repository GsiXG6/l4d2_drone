#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <l4d2_drone>
#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_NAME			"l4d2_drone"
#define PLUGIN_VERSION		"0.0"
#define PLUGIN_TAG			"\x04[DRONE]:\x01"

#define SIZE_ENTITY			2000
#define INTERVAL_LIFE		0.1

#define MDL_DUMMY			"models/props_fairgrounds/alligator.mdl"
#define MDL_BODY			"models/f18/f18.mdl"
#define MDL_ARM				"models/weapons/melee/w_golfclub.mdl"
#define MDL_ROTOR			"models/props_junk/garbage_sodacan01a.mdl"
//#define MDL_ROTOR			"models/missiles/f18_agm65maverick.mdl"
//#define MDL_ROTOR			"models/w_models/weapons/w_eq_painpills.mdl"
//#define MDL_ROTOR			"models/ghostanim.mdl"
//#define MDL_ROTOR			"models/props_junk/barrel_fire.mdl"
//#define MDL_ROTOR			"models/props_c17/oildrum001.mdl"
//#define MDL_ROTOR			"models/props_collectables/coin.mdl"
#define MDL_HELIY			"models/c2m5_helicopter_extraction/c2m5_helicopter.mdl"

#define SND_TIMEOUT			"ambient/machines/steam_release_2.wav"

#define BEAMSPRITE_BLOOD	"materials/sprites/bloodspray.vmt"
#define BEAMSPRITE_BUBBLE	"materials/sprites/bubble.vmt"
#define BEAMSPRITE_SKULL	"materials/sprites/skull_icon.vmt"

ConVar	g_ConVarPetEnable;
bool	g_bIsPetEnable;
bool	g_bIsRoundStart;

//int	g_iBeamSprite_Blood;
//int 	g_iBeamSprite_Bubble;

float	g_fDrone_Life[SIZE_ENTITY];
float	g_fDrone_Force[SIZE_ENTITY][POS_THRUST_TOTAL];		// left right force on/off
int		g_iDrone_Thrust[SIZE_ENTITY][POS_THRUST_TOTAL];
int		g_iDroneEnvSteam[SIZE_ENTITY][POS_THRUST_TOTAL];	// cosmetic
int		g_iClient_Drone[MAXPLAYERS+1]	= { -1, ... };		// guess what.. your crush... :)
int		g_iDroneMaster[SIZE_ENTITY]		= { -1, ... };		// guess what.. your crush... :)
bool	g_bIsHittingWall[SIZE_ENTITY];
///// debigging var ////
//bool g_bIsTestedOnce	= false;
int BestFriendForever;


public Plugin myinfo =
{
	name		= PLUGIN_NAME,
	author		= "GsiX",
	description	= "Player pet",
	version		= PLUGIN_VERSION,
	url			= ""
}

public void OnPluginStart()
{
	char plName[16];
	FormatEx( plName, sizeof( plName ), "%s_version", PLUGIN_NAME );
	
	CreateConVar( plName, PLUGIN_VERSION, "Plugin version", FCVAR_DONTRECORD );
	g_ConVarPetEnable	= CreateConVar( "l4d2_drone_enabled",	"1",	"0:Off, 1:On,  Toggle plugin on/off", FCVAR_SPONLY|FCVAR_NOTIFY);
	AutoExecConfig( true, PLUGIN_NAME );
	
	HookEvent( "round_start",	EVENT_RoundStartEnd, EventHookMode_PostNoCopy );
	HookEvent( "round_end",		EVENT_RoundStartEnd, EventHookMode_PostNoCopy );
	HookEvent( "player_spawn",	EVENT_PlayerSpawnDeath );
	HookEvent( "player_death",	EVENT_PlayerSpawnDeath );
	
	g_ConVarPetEnable.AddChangeHook( CVAR_Changed );
	
	UpdateCVar();
	
	//bind f8 "say /pet_model 30"
	RegAdminCmd( "pet_model", AdminModelSpawn,	ADMFLAG_GENERIC );
	
	//bind f7 "say /pet_home"
	RegAdminCmd( "pet_home", AdminCallDrone,	ADMFLAG_GENERIC );
	
	//bind KP_INS "say /pet_move 0"
	//bind KP_HOME "say /pet_move 1"
	//bind KP_UPARROW "say /pet_move 2"
	//bind KP_LEFTARROW "say /pet_move 3"
	//bind KP_5 "say /pet_move 4"
	//bind KP_END "say /pet_move 5"
	//bind KP_DOWNARROW "say /pet_move 6"
	RegAdminCmd( "pet_move", AdminModelMove,	ADMFLAG_GENERIC );
}

public void OnMapStart()
{
	PrecacheModel( MDL_DUMMY, true );
	PrecacheModel( MDL_BODY, true );
	PrecacheModel( MDL_ROTOR, true );
	PrecacheModel( MDL_ARM, true );
	PrecacheModel( MDL_HELIY, true );
	
	PrecacheSound( SND_TIMEOUT, true );
	
	//PrecacheModel( BEAMSPRITE_BUBBLE, true );
	//g_iBeamSprite_Blood	= PrecacheModel( BEAMSPRITE_BLOOD );
	//g_iBeamSprite_Bubble	= PrecacheModel( BEAMSPRITE_BUBBLE );
	//g_iBeamSprite_Skull	= PrecacheModel( BEAMSPRITE_SKULL );
}

public Action AdminModelMove( int client, any args )
{
	if ( IsValidSurvivor( client ))
	{
		if ( args < 1 )
		{
			ReplyToCommand( client, "%s Usage: pet_move 0, 1, 2, 3, 4, 5, 6(args). 1 arg at a time", PLUGIN_TAG );
			return Plugin_Handled;
		}
		
		char arg1[8];
		GetCmdArg( 1, arg1, sizeof( arg1 ));
		int move = StringToInt( arg1 );
		if( move < 0 || move > 6 )
		{
			ReplyToCommand( client, "%s valid args 0 to 6", PLUGIN_TAG );
			return Plugin_Handled;
		}
		
		if( BestFriendForever > MaxClients && IsValidEntity( BestFriendForever ))
		{
			float pos_start[3];
			float ang_start[3];
			GetEntOrigin( BestFriendForever, pos_start, 0.0 );
			GetEntAngle( BestFriendForever, ang_start, 0.0, 0 );
			if( move == 0 )
			{
				ReplyToCommand( client, "%s POS: %f | %f | %f", PLUGIN_TAG, pos_start[0], pos_start[1], pos_start[2] );
				ReplyToCommand( client, "%s ANG: %f | %f | %f", PLUGIN_TAG, ang_start[0], ang_start[1], ang_start[2] );
			}
			else if( move == 1 )
			{
				pos_start[0] += 1.0;
				TeleportEntity( BestFriendForever, pos_start, NULL_VECTOR, NULL_VECTOR );
			}
			else if( move == 2 )
			{
				pos_start[0] -= 1.0;
				TeleportEntity( BestFriendForever, pos_start, NULL_VECTOR, NULL_VECTOR );
			}
			else if( move == 3 )
			{
				pos_start[1] += 1.0;
				TeleportEntity( BestFriendForever, pos_start, NULL_VECTOR, NULL_VECTOR );
			}
			else if( move == 4 )
			{
				pos_start[1] -= 1.0;
				TeleportEntity( BestFriendForever, pos_start, NULL_VECTOR, NULL_VECTOR );
			}
			else if( move == 5 )
			{
				ang_start[1] += 1.0;
				TeleportEntity( BestFriendForever, NULL_VECTOR, ang_start, NULL_VECTOR );
			}
			else if( move == 6 )
			{
				ang_start[1] -= 1.0;
				TeleportEntity( BestFriendForever, NULL_VECTOR, ang_start, NULL_VECTOR );
			}
		}
		else
		{
			ReplyToCommand( client, "%s invalid Helicopter to move", PLUGIN_TAG );
		}
	}
	return Plugin_Handled;
}

public Action AdminModelSpawn( int client, any args )
{
	if ( IsValidSurvivor( client ))
	{
		if ( g_iClient_Drone[client] != -1 )
		{
			ReplyToCommand( client, "%s You still have drone", PLUGIN_TAG );
			return Plugin_Handled;
		}
		
		if ( args < 1 )
		{
			ReplyToCommand( client, "%s Usage: pet_model 10(time in secs)", PLUGIN_TAG );
			return Plugin_Handled;
		}
		
		char arg1[8];
		GetCmdArg( 1, arg1, sizeof( arg1 ));
		float time = StringToFloat( arg1 );
		if( time < 1.0 )
		{
			ReplyToCommand( client, "%s first Args time in secs. time >= 1 sec", PLUGIN_TAG );
			return Plugin_Handled;
		}
		
		float pos_start[3];
		float ang_start[3];
		float pos_buffe[3];
		
		GetClientEyePosition( client, pos_start );
		GetClientEyeAngles( client, ang_start );
		bool gotpos = TraceRayGetEndpoint( pos_start, ang_start, client, pos_buffe );
		if( gotpos )
		{
			pos_buffe[2] += DRONE_HEIGHT;
			ang_start[0] = 0.0;
			ang_start[2] = 0.0;
			int drone = CreateLovelyDrone( client, pos_buffe, ang_start, time );
			if( drone > MaxClients && IsValidEntity( drone ))
			{
				g_iClient_Drone[client] = EntIndexToEntRef( drone );
			}
		}
	}
	return Plugin_Handled;
}

public Action AdminCallDrone( int client, any args )
{
	if ( IsValidSurvivor( client ))
	{
		int drone = EntRefToEntIndex( g_iClient_Drone[client] );
		if( drone > 0 && IsValidEntity( drone ))
		{
			float pos[3];
			float ang[3];
			GetEntOrigin( client, pos, DRONE_HEIGHT );
			GetEntAngle( client, ang, 0.0, 0 );
			TeleportEntity( drone, pos, ang, NULL_VECTOR );
			ReplyToCommand( client, "%s Calling Drone home", PLUGIN_TAG );
		}
		else
		{
			ReplyToCommand( client, "%s You have no drone", PLUGIN_TAG );
		}
	}
	return Plugin_Handled;
}

public void CVAR_Changed( Handle convar, const char[] oldValue, const char[] newValue )
{
	UpdateCVar();
}

void UpdateCVar()
{
	g_bIsPetEnable = g_ConVarPetEnable.BoolValue;
}

public Action OnPlayerRunCmd( int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon )
{
	if (( buttons & IN_USE ) && ( buttons & IN_ATTACK2 ))
	{
		if( IsValidSurvivor( client ))
		{
			int pet = EntRefToEntIndex( g_iClient_Drone[client] );
			if( pet > MaxClients && IsValidEntity( pet ))
			{
				float pos[3];
				float ang[3];
				GetClientEyePosition( client, pos );
				GetClientEyeAngles( client, ang );
				int target = TraceRayGetEntity( pos, ang, client );
				if( target > 0 && IsValidEdict( target ))
				{
					g_iDroneMaster[pet] = EntIndexToEntRef( target );
				}
				else
				{
					g_iDroneMaster[pet] = -1;
				}
			}
		}
	}
	return Plugin_Continue;
}

public void EVENT_RoundStartEnd ( Event event, const char[] name, bool dontBroadcast )
{
	if( StrEqual( name, "round_start", false ))
	{
		g_bIsRoundStart = true;
	}
	else if( StrEqual( name, "round_end", false ))
	{
		g_bIsRoundStart = false;
	}
}

public void EVENT_PlayerSpawnDeath( Event event, const char[] name, bool dontBroadcast )
{
	if( !g_bIsPetEnable ) return;
	
	int userid = event.GetInt( "userid" );
	int client = GetClientOfUserId( userid );
	if ( IsValidSurvivor( client ))
	{
		if( StrEqual( name, "player_spawn", false ))
		{
			// spawn
			g_iClient_Drone[client] = -1;
		}
		else if( StrEqual( name, "player_death", false ))
		{
			// death
		}
	}
}

int CreateLovelyDrone( int owner, float pos[3], float ang[3], float life )
{
	int drone = CreateParent( MDL_DUMMY, pos, ang, 0.01 );
	if( drone != -1 )
	{
		g_iDroneMaster[drone] = -1;
		SetOwner( drone, owner );
		
		float pos_attch[4][3];
		float pos_origin[3]	= { 0.0, 0.0, 0.0 };
		float ang_adjust[3]	= { 0.0, 0.0, 0.0 };
		float arm_length	= 15.0;
		float ang_start		= 45.0;
		float ang_incre		= 90.0;
		
		int i, temp, dummy;
		///////////////////////////////////////
		//////////////// ROTOR ////////////////
		///////////////////////////////////////
		for( i = POS_ROTOR_1; i <= POS_ROTOR_4; i++ )
		{
			// thrust to lift our drone at 4 arm pos. we build 1 by 1
			SetArray3DFloat( 0.0, 0.0, 0.0, pos_attch[i] );
			GetLocalAttachmentPos( ang_start, (arm_length - 2.0), pos_attch[i] );
			pos_attch[i][2] = 1.0; 
			SetArray3DFloat( -90.0, ang_start, 0.0, ang_adjust );
			CreateSkin( drone, MDL_ARM, pos_attch[i], ang_adjust, 0.65, g_iColor_White, 255 );
			
			SetArray3DFloat( 0.0, 0.0, 0.0, pos_attch[i] );
			GetLocalAttachmentPos( ang_start, arm_length, pos_attch[i] );
			
			// rotor force
			SetArray3DFloat( -90.0, 0.0, 0.0, ang_adjust );
			g_fDrone_Force[drone][i] = FORCE_UPWARD;
			temp = CreateThrust( drone, pos_attch[i], ang_adjust, g_fDrone_Force[drone][i] );
			g_iDrone_Thrust[drone][i] = EntIndexToEntRef( temp );
			
			// crocodile model, act as rotor parent
			SetArray3DFloat( 0.0, 0.0, 0.0, ang_adjust );
			dummy = CreateSkin( drone, MDL_DUMMY, pos_attch[i], ang_adjust, 0.01, g_iColor_White, 0 );
			
			// exaust skin coke can
			SetArray3DFloat( 0.0, 0.0, 1.0, pos_origin );
			SetArray3DFloat( 180.0, 0.0, 0.0, ang_adjust );
			CreateSkin( dummy, MDL_ROTOR, pos_origin, ang_adjust, 1.0, g_iColor_Red, 255 );
			
			// exaust env_steam
			SetArray3DFloat( 0.0, 0.0, -3.0, pos_origin );
			SetArray3DFloat( 90.0, 0.0, 0.0, ang_adjust );
			temp = CreateEnvSteam( dummy, pos_origin, ang_adjust, g_iColor_Exaust );
			g_iDroneEnvSteam[drone][i] = EntIndexToEntRef( temp );
			
			ang_start += ang_incre;
		}
		
		
		///////////////////////////////////////
		///////////////// TAIL ////////////////
		///////////////////////////////////////
		// thrust move forward
		SetArray3DFloat( -18.0, -2.5, -1.0, pos_origin );
		SetArray3DFloat( 0.0, 0.0, 0.0, ang_adjust );
		g_fDrone_Force[drone][POS_THRUST_MAIN1] = FORCE_NONE;
		temp = CreateThrust( drone, pos_origin, ang_adjust, g_fDrone_Force[drone][POS_THRUST_MAIN1] );
		g_iDrone_Thrust[drone][POS_THRUST_MAIN1] = EntIndexToEntRef( temp );
		SetArray3DFloat( 180.0, 0.0, 0.0, ang_adjust );
		temp = CreateEnvSteam( drone, pos_origin, ang_adjust, g_iColor_Exaust );
		g_iDroneEnvSteam[drone][POS_THRUST_MAIN1] = EntIndexToEntRef( temp );
		
		SetArray3DFloat( -18.0, 2.5, -1.0, pos_origin );
		SetArray3DFloat( 0.0, 0.0, 0.0, ang_adjust );
		g_fDrone_Force[drone][POS_THRUST_MAIN2] = FORCE_NONE;
		temp = CreateThrust( drone, pos_origin, ang_adjust, g_fDrone_Force[drone][POS_THRUST_MAIN2] );
		g_iDrone_Thrust[drone][POS_THRUST_MAIN2] = EntIndexToEntRef( temp );
		SetArray3DFloat( 180.0, 0.0, 0.0, ang_adjust );
		temp = CreateEnvSteam( drone, pos_origin, ang_adjust, g_iColor_Exaust );
		g_iDroneEnvSteam[drone][POS_THRUST_MAIN2] = EntIndexToEntRef( temp );
		
		
		///////////////////////////////////////
		////////////// NAVIGATION /////////////
		///////////////////////////////////////
		// thrust to move against east
		SetArray3DFloat( 0.0, 15.0, 0.0, pos_origin );
		SetArray3DFloat( 0.0, ANGLE_WEST, 0.0, ang_adjust );
		g_fDrone_Force[drone][POS_THRUST_EAST] = FORCE_NONE;
		temp = CreateThrust( drone, pos_origin, ang_adjust, g_fDrone_Force[drone][POS_THRUST_EAST] );
		g_iDrone_Thrust[drone][POS_THRUST_EAST] = EntIndexToEntRef( temp );
		
		// thrust to move against nort east
		SetArray3DFloat( 15.0, 15.0, 0.0, pos_origin );
		SetArray3DFloat( 0.0, ANGLE_NTWEST, 0.0, ang_adjust );
		g_fDrone_Force[drone][POS_THRUST_NTEAST] = FORCE_NONE;
		temp = CreateThrust( drone, pos_origin, ang_adjust, g_fDrone_Force[drone][POS_THRUST_NTEAST] );
		g_iDrone_Thrust[drone][POS_THRUST_NTEAST] = EntIndexToEntRef( temp );
		
		// thrust to move against nort
		SetArray3DFloat( 15.0, 0.0, 0.0, pos_origin );
		SetArray3DFloat( 0.0, 180.0, 0.0, ang_adjust );
		g_fDrone_Force[drone][POS_THRUST_NORTN] = FORCE_NONE;
		temp = CreateThrust( drone, pos_origin, ang_adjust, g_fDrone_Force[drone][POS_THRUST_NORTN] );
		g_iDrone_Thrust[drone][POS_THRUST_NORTN] = EntIndexToEntRef( temp );
		
		// thrust to move against nort west
		SetArray3DFloat( -15.0, 15.0, 0.0, pos_origin );
		SetArray3DFloat( 0.0, ANGLE_NTEAST, 0.0, ang_adjust );
		g_fDrone_Force[drone][POS_THRUST_NTWEST] = FORCE_NONE;
		temp = CreateThrust( drone, pos_origin, ang_adjust, g_fDrone_Force[drone][POS_THRUST_NTWEST] );
		g_iDrone_Thrust[drone][POS_THRUST_NTWEST] = EntIndexToEntRef( temp );
		
		// thrust to move left
		SetArray3DFloat( 0.0, -15.0, 0.0, pos_origin );
		SetArray3DFloat( 0.0, ANGLE_EAST, 0.0, ang_adjust );
		g_fDrone_Force[drone][POS_THRUST_WEST] = FORCE_NONE;
		temp = CreateThrust( drone, pos_origin, ang_adjust, g_fDrone_Force[drone][POS_THRUST_WEST] );
		g_iDrone_Thrust[drone][POS_THRUST_WEST] = EntIndexToEntRef( temp );
		
		// thrust to rotate left right
		SetArray3DFloat( 0.0, 0.0, 0.0, pos_origin );
		SetArray3DFloat( 0.0, 0.0, 0.0, ang_adjust );
		g_fDrone_Force[drone][POS_THRUST_ROTATE] = FORCE_NONE;
		temp = CreateTorque( drone, pos_origin, ang_adjust, g_fDrone_Force[drone][POS_THRUST_ROTATE] );
		g_iDrone_Thrust[drone][POS_THRUST_ROTATE] = EntIndexToEntRef( temp );
		
		
		///////////////////////////////////////
		/////////////// COSMETIC //////////////
		///////////////////////////////////////
		// body F18 main skin what appear to player
		SetArray3DFloat( -7.0, 0.0, 0.0, pos_origin );
		SetArray3DFloat( 0.0, 0.0, 0.0, ang_adjust );
		CreateSkin( drone, MDL_BODY, pos_origin, ang_adjust, 0.05, g_iColor_White, 255 );
		
		// small small Helicopter
		SetArray3DFloat( 74.0, 104.0, 10.0, pos_origin );
		SetArray3DFloat( 0.0, 91.0, 0.0, ang_adjust );
		BestFriendForever = CreatEntAnimation( drone, MDL_HELIY, "hover1", pos_origin, ang_adjust, 0.03 );
		
		///////////////////////////////////////
		////////////////// GUN ////////////////
		///////////////////////////////////////
		// Gatling Gun
		SetArray3DFloat( 25.0, 0.0, -5.0, pos_origin );
		CreateGatlingGun( drone, pos_origin, ang_adjust, 0.1, 300.0 );
		
		
		///////////////////////////////////////
		/////////////// CONSTRAIN /////////////
		///////////////////////////////////////
		// constrain our drone to always stand upward
		SetArray3DFloat( 90.0, 0.0, 0.0, ang_adjust );
		CreateUprightLifting( drone, pos_origin, ang_adjust );
		
		// constrain our drone to always stand flat against world
		SetArray3DFloat( 0.0, 0.0, 0.0, ang_adjust );
		CreateUprightConstrain( drone, pos_origin, ang_adjust );
		
		g_fDrone_Life[drone] = life;
		CreateTimer( INTERVAL_LIFE, Timer_DroneThink, EntIndexToEntRef( drone ), TIMER_REPEAT );
		PrintToChat( owner, "%s Drone created", PLUGIN_TAG );
	}
	return drone;
}

public Action Timer_DroneThink( Handle timer, any entref )
{
	int entity = EntRefToEntIndex( entref );
	if ( entity > MaxClients && IsValidEntity( entity ))
	{
		if( g_fDrone_Life[entity] > 0.0 && g_bIsRoundStart )
		{
			g_fDrone_Life[entity] -= INTERVAL_LIFE;
			
			int client = GetOwner( entity );
			if( IsValidSurvivor( client ))
			{
				float pos_entity[3];
				float pos_target[3];
				GetEntOrigin( entity, pos_entity, 0.0 );
				GetEntOrigin( client, pos_target, DRONE_HEIGHT );
				
				if( g_iDroneMaster[entity] != -1 )
				{
					int target = EntRefToEntIndex( g_iDroneMaster[entity] );
					if( target > 0 && IsValidEdict( target ))
					{
						GetEntOrigin( target, pos_target, DRONE_HEIGHT );
					}
					else
					{
						g_iDroneMaster[entity] = -1;
						PrintToChat( client, "%s Target cleared", PLUGIN_TAG );
					}
				}
				
				Think_Lifting( entity, pos_entity, pos_target );
				Think_Direction( entity, pos_entity, pos_target );
				Think_Forward( entity, pos_entity, pos_target );
				Think_SideObstackle( entity, POS_THRUST_EAST, ANGLE_EAST, pos_entity );
				Think_SideObstackle( entity, POS_THRUST_WEST, ANGLE_WEST, pos_entity );
				
				Think_FrontObstackle( entity, POS_THRUST_NTEAST, ANGLE_NTEAST, pos_entity );
				Think_FrontObstackle( entity, POS_THRUST_NORTN, ANGLE_NORTH, pos_entity );
				Think_FrontObstackle( entity, POS_THRUST_NTWEST, ANGLE_NTWEST, pos_entity );
				
				return Plugin_Continue;
			}
		}
		
		int owner = GetOwner( entity );
		if( IsValidSurvivor( owner ))
		{
			g_iClient_Drone[owner] = -1;
		}
		Entity_KillHierarchy( entity );
	}
	return Plugin_Stop;
}

void Think_Lifting( int entity, float pos_entity[3], float pos_target[3] )
{
	float center	= 20.0;
	float distance	= pos_entity[2] - pos_target[2];
	
	// positive value apply force push downward
	// negative value apply force push upward
	float tolerance = 5.0;
	float direction = distance - center;
	if( direction > (tolerance * -1.0 ) && direction < tolerance )
	{
		direction = FORCE_FALL * -1.0;
	}
	
	float force = FORCE_UPWARD - direction;
	if( g_fDrone_Force[entity][POS_ROTOR_1] != force )
	{
		int temp;
		for( int i = POS_ROTOR_1; i <= POS_ROTOR_4; i++ )
		{
			g_fDrone_Force[entity][i] = force;
			temp = EntRefToEntIndex( g_iDrone_Thrust[entity][i] );
			if( temp > MaxClients && IsValidEntity( temp ))
			{
				SetThrusterTorque( temp, force );
			}
			
			temp = EntRefToEntIndex( g_iDroneEnvSteam[entity][i] );
			if( temp > MaxClients && IsValidEntity( temp ))
			{
				if( force < 180.0 )
				{
					SetSteamLength( temp, STEAM_LEN_IDLE );
				}
				else if( force < 203.0 )
				{
					SetSteamLength( temp, STEAM_LEN_THRUST1 );
				}
				else
				{
					SetSteamLength( temp, STEAM_LEN_THRUST2 );
				}
			}
		}
	}
	//PrintToChatAll( "force: %f ", force );
}

void Think_Direction( int entity, float pos_entity[3], float pos_target[3] )
{
	float pos_buff[3];
	SetArray3DFloat( pos_target[0], pos_target[1], pos_entity[2], pos_buff );
	
	float ang_entity[3];
	float ang_guide[3];
	GetEntAngle( entity, ang_entity, 0.0, 0 );
	MakeVectorFromPoints( pos_entity, pos_buff, ang_guide );
	NormalizeVector( ang_guide, ang_guide );
	GetVectorAngles( ang_guide, ang_guide );
	
	float tolerance = 2.0;
	float direction = AngleDifference( ang_guide[1], ang_entity[1] ) * -1.0;
	if( direction > (tolerance * -1.0 ) && direction < tolerance )
	{
		direction = 0.0;
	}
	
	// negative value turn right
	// positive value turn left
	float force = FORCE_ROTATE * direction;
	
	if( g_fDrone_Force[entity][POS_THRUST_ROTATE] != force )
	{
		g_fDrone_Force[entity][POS_THRUST_ROTATE] = force;
		
		int length = STEAM_LEN_IDLE;
		float ang_ang[3] = { 180.0, 0.0, 0.0 };
		if( force == FORCE_NONE )
		{
			ang_ang[AXIS_YAW] = GEAR_NONE;
		}
		else
		{
			length = STEAM_LEN_THRUST1;
			ang_ang[AXIS_YAW] = GEAR_LEFT;
			if( force > FORCE_NONE )
			{
				ang_ang[AXIS_YAW] = GEAR_RIGHT;
			}
		}

		int temp1 = EntRefToEntIndex( g_iDroneEnvSteam[entity][POS_THRUST_MAIN1] );
		int temp2 = EntRefToEntIndex( g_iDroneEnvSteam[entity][POS_THRUST_MAIN2] );
		if( temp1 > MaxClients && temp2 > MaxClients && IsValidEntity( temp1 ) && IsValidEntity( temp2 ))
		{
			TeleportEntity( temp1, NULL_VECTOR, ang_ang, NULL_VECTOR );
			TeleportEntity( temp2, NULL_VECTOR, ang_ang, NULL_VECTOR );
			SetSteamLength( temp1, length );
			SetSteamLength( temp2, length );
		}
		
		int temp = EntRefToEntIndex( g_iDrone_Thrust[entity][POS_THRUST_ROTATE] );
		if( temp > MaxClients && IsValidEntity( temp ))
		{
			SetThrusterTorque( temp, force );
		}
	}
}

void Think_Forward( int entity, float pos_entity[3], float pos_target[3] )
{
	float vec_buff[3];
	SetArray3DFloat( pos_target[0], pos_target[1], pos_entity[2], vec_buff );
	float dist	= GetVectorDistance( pos_entity, vec_buff );
	float force	= FORCE_NONE;

	if( dist > 100.0 && !g_bIsHittingWall[entity] )
	{
		force = FORCE_FORWARD * dist;
		if( force > MAXIMUM_SPEED )
		{
			force = MAXIMUM_SPEED;
		}
	}
	
	if( g_fDrone_Force[entity][POS_THRUST_MAIN1] != force )
	{
		g_fDrone_Force[entity][POS_THRUST_MAIN1] = force;
		g_fDrone_Force[entity][POS_THRUST_MAIN2] = force;
		
		float gear;
		int i, exaust, parent, length;
		for( i = 0; i < 4; i++ )
		{
			exaust = EntRefToEntIndex( g_iDroneEnvSteam[entity][i] );
			if( exaust > MaxClients && IsValidEntity( exaust ))
			{
				gear = GEAR_NONE;
				length = STEAM_LEN_IDLE;
				if( force != FORCE_NONE )
				{
					gear = GEAR_FORWARD;
					length = STEAM_LEN_THRUST1;
				}
				parent = GetEntityParent( exaust );
				GetEntAngle( parent, vec_buff, 0.0, 0 );
				vec_buff[0] = gear;
				TeleportEntity( parent, NULL_VECTOR, vec_buff, NULL_VECTOR );
				SetSteamLength( exaust, length );
			}
		}
		/*
		if( g_fDrone_Force[entity][POS_THRUST_MAIN1] == FORCE_NONE )
		{
			EmitSoundToAll( SND_TIMEOUT, entity, SNDCHAN_AUTO );
		}*/
		SetThrusterTorque( g_iDrone_Thrust[entity][POS_THRUST_MAIN1], force );
		SetThrusterTorque( g_iDrone_Thrust[entity][POS_THRUST_MAIN2], force );
	}
}

void Think_SideObstackle( int entity, int direction, float rotation, float pos_entity[3] )
{
	// sensor wall left, front, right
	float ang_start[3];
	float pos_output[3];
	GetEntAngle( entity, ang_start, rotation, AXIS_YAW );
	
	bool gotpos = TraceRayGetEndpoint( pos_entity, ang_start, entity, pos_output );
	if( gotpos )
	{
		float force = 0.0;
		float dist = GetVectorDistance( pos_entity, pos_output );
		if( dist <= FORCE_RADIUS )
		{
			float mult = (FORCE_RADIUS - dist) * 1.5;
			if( mult < 0.0 )
			{
				mult = 0.0;
			}
			
			force = FORCE_FORWARD * mult;
			//PrintToChatAll( "%s Force %f | Dir %d", PLUGIN_TAG, force, direction );
		}
		
		if( g_fDrone_Force[entity][direction] != force )
		{
			g_fDrone_Force[entity][direction] = force;
			
			int trust = EntRefToEntIndex( g_iDrone_Thrust[entity][direction] );
			if( trust > MaxClients && IsValidEntity( trust ))
			{
				SetThrusterTorque( trust, force );
			}
			
			int i, exaust, rotor, length;
			float gear;
			for( i = POS_ROTOR_1; i <= POS_ROTOR_4; i++ )
			{
				exaust = EntRefToEntIndex( g_iDroneEnvSteam[entity][i] );
				if( exaust > MaxClients && IsValidEntity( exaust ))
				{
					length = STEAM_LEN_IDLE;
					rotor = GetEntityParent( exaust );
					GetEntAngle( rotor, ang_start, 0.0, 0 );
					gear = GEAR_NONE;
					if( force != FORCE_NONE )
					{
						length = STEAM_LEN_THRUST1;
						gear = GEAR_LEFT;
						if( direction == POS_THRUST_EAST )
						{
							gear = GEAR_RIGHT;
						}
					}
					ang_start[2] = gear;
					TeleportEntity( rotor, NULL_VECTOR, ang_start, NULL_VECTOR );
					SetSteamLength( exaust, length );
				}
			}
		}
	}
}

void Think_FrontObstackle( int entity, int direction, float rotation, float pos_entity[3] )
{
	// sensor wall left, front, right
	float ang_start[3];
	float pos_output[3];
	GetEntAngle( entity, ang_start, rotation, AXIS_YAW );
	
	bool gotpos = TraceRayGetEndpoint( pos_entity, ang_start, entity, pos_output );
	if( gotpos )
	{
		g_bIsHittingWall[entity] = false;
		
		float force = 0.0;
		float dist = GetVectorDistance( pos_entity, pos_output );
		if( dist <= FORCE_RADIUS )
		{
			g_bIsHittingWall[entity] = true;
			float mult = (FORCE_RADIUS - dist) * 1.5;
			if( mult < 0.0 )
			{
				mult = 0.0;
			}
			
			force = FORCE_FORWARD * mult;
			//PrintToChatAll( "%s Force %f | Dir %d", PLUGIN_TAG, force, direction );
		}
		
		if( g_fDrone_Force[entity][direction] != force )
		{
			g_fDrone_Force[entity][direction] = force;
			
			int trust = EntRefToEntIndex( g_iDrone_Thrust[entity][direction] );
			if( trust > MaxClients && IsValidEntity( trust ))
			{
				SetThrusterTorque( trust, force );
			}
			
			int i, exaust, rotor, length;
			float gear;
			for( i = POS_ROTOR_1; i <= POS_ROTOR_4; i++ )
			{
				exaust = EntRefToEntIndex( g_iDroneEnvSteam[entity][i] );
				if( exaust > MaxClients && IsValidEntity( exaust ))
				{
					length = STEAM_LEN_IDLE;
					rotor = GetEntityParent( exaust );
					GetEntAngle( rotor, ang_start, 0.0, 0 );
					gear = GEAR_NONE;
					if( force != FORCE_NONE )
					{
						length = STEAM_LEN_THRUST1;
						gear = GEAR_BACKWARD;
					}
					ang_start[0] = gear;
					TeleportEntity( rotor, NULL_VECTOR, ang_start, NULL_VECTOR );
					SetSteamLength( exaust, length );
				}
			}
		}
	}
}

void SetSteamLength( int entity, int length )
{ 
	AcceptEntityInput( entity, "TurnOff" );
	char len[8];
	FormatEx( len, sizeof(len), "%d", length );
	DispatchKeyValue( entity, "JetLength", len );
	AcceptEntityInput( entity, "TurnOn" );
}

stock void Hit_The_Fucking_Emergency_Break( int entity )
{
	// use this fucking midair magic emergency break ONLY for heavier prop physic. ugly solution
	float ang[3];
	GetEntAngle( entity, ang, 0.0, 0 );
	TeleportEntity( entity, NULL_VECTOR, ang, NULL_VECTOR );
	//PrintToChatAll( "%s Drone is taking a fucking break", PLUGIN_TAG );
}
