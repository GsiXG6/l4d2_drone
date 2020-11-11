#define AXIS_PITCH			0			// axis rotation of our angle manipulation
#define AXIS_YAW			1
#define AXIS_ROLL			2

#define DRONE_HEIGHT		60.0
#define FORCE_NONE			0.0
#define FORCE_UPWARD		200.0
#define FORCE_LIFT			10.0
#define FORCE_FALL			2.0
#define FORCE_ROTATE		15.0
#define FORCE_FORWARD		5.0
#define FORCE_RADIUS		80.0

#define MAXIMUM_SPEED		1000.0

#define GEAR_NONE			0.0
#define GEAR_FORWARD		40.0
#define GEAR_BACKWARD		-40.0
#define GEAR_LEFT			45.0
#define GEAR_RIGHT			-45.0



#define ANGLE_EAST			-90.0
#define ANGLE_NTEAST		-45.0
#define ANGLE_NORTH			0.0
#define ANGLE_NTWEST		45.0
#define ANGLE_WEST			90.0

#define	POS_ROTOR_1			0
#define	POS_ROTOR_2			1
#define	POS_ROTOR_3			2
#define	POS_ROTOR_4			3
#define	POS_THRUST_MAIN1	4
#define	POS_THRUST_MAIN2	5
#define	POS_THRUST_EAST		6
#define	POS_THRUST_NTEAST	7
#define	POS_THRUST_NORTN	8
#define	POS_THRUST_NTWEST	9
#define	POS_THRUST_WEST		10
#define	POS_THRUST_ROTATE	11
#define POS_THRUST_TOTAL	12

#define STEAM_LEN_IDLE		2
#define STEAM_LEN_THRUST1	5
#define STEAM_LEN_THRUST2	10


int g_iColor_White[3]	= { 255, 255, 255 };
int g_iColor_Red[3]		= { 255, 000, 000 };
//int g_iColor_LRed[3]	= { 255, 128, 128 };
//int g_iColor_Green[3]	= { 000, 255, 000 };
//int g_iColor_LGreen[3]	= { 128, 255, 128 };
//int g_iColor_Blue[3]	= { 000, 000, 255 };
//int g_iColor_LBlue[3]	= { 000, 128, 255 };
//int g_iColor_Pinky[3]	= { 255, 000, 255 };
//int g_iColor_Yellow[3]	= { 255, 255, 000 };
//int g_iColor_Dark[3]	= { 128, 128, 128 };
int g_iColor_Exaust[3]	= { 060, 080, 200 };

stock int CreateParent( const char[] model, float pos[3], float ang[3], float model_scale )
{
	int parent = CreateEntityByName( "prop_physics_override" );
	if( parent != -1 )
	{
		DispatchKeyValueVector( parent, "origin", pos );
		DispatchKeyValueVector( parent, "angles", ang );
		
		char parentName[16];
		FormatEx( parentName, sizeof( parentName ), "parent_%d", parent );
		DispatchKeyValue( parent, "targetname", parentName );
		
		char spawnflags[32];
		Format( spawnflags, sizeof( spawnflags ), "%i", 2 | 4 | 128 | 512 | 8192 ); // No Damage | No Collide | Not Rotor Wash | No Pickup | Server side
		DispatchKeyValue( parent, "spawnflags", spawnflags );
		DispatchKeyValue( parent, "model", model );
		SetEntPropFloat( parent, Prop_Send,"m_flModelScale", model_scale );
		DispatchKeyValueFloat( parent, "massscale", 0.01 );
		DispatchKeyValueFloat( parent, "inertiascale", 0.01 );
		//DispatchKeyValueFloat( parent, "forcetoenablemotion", 1.0 );
		DispatchKeyValue( parent, "nodamageforces", "1" );
		DispatchKeyValue( parent, "solid", "0" );
		//DispatchKeyValue( parent, "disableshadows", "1" );
		
		//SetEntityGravity( parent, 0.1 );
		//SetEntProp( parent, Prop_Send, "m_usSolidFlags", 12 );
		//SetEntProp( parent, Prop_Data, "m_nSolidType", 6 );
		//SetEntProp( parent, Prop_Send, "m_CollisionGroup", 0 );

		DispatchSpawn( parent );
		SetColor( parent, g_iColor_White, 0 );
	}
	return parent;
}

stock int CreateSkin( int parent, const char[] model, float pos[3], float ang[3], float model_scale, int color[3], int alpha )
{
	int skin = CreateEntityByName( "prop_dynamic_override" );
	if( skin != -1 )
	{
		char ownName[32];
		FormatEx( ownName, sizeof( ownName ), "skin_%d", skin );
		DispatchKeyValue( skin, "targetname", ownName );
		
		char parentName[32];
		GetEntityName( parent, parentName );
		SetVariantString( parentName );
		AcceptEntityInput( skin, "SetParent" );
		
		char spawnflags[16];
		FormatEx( spawnflags, sizeof( spawnflags ), "%i", 8 | 512 ); // No collision | Not blockable
		DispatchKeyValue( skin, "spawnflags", spawnflags );
		//SetEntProp( skin, Prop_Send, "m_CollisionGroup", 0 ); 
		
		//DispatchKeyValue( skin, "solid", "0" );
		DispatchKeyValue( skin, "model", model );
		SetEntPropFloat( skin, Prop_Send,"m_flModelScale", model_scale );
		DispatchKeyValueFloat( skin, "fademindist", 10000.0 );
		DispatchKeyValueFloat( skin, "fademaxdist", 10000.0 );
		DispatchKeyValueFloat( skin, "fadescale", 0.0 );
		DispatchKeyValue( skin, "disableshadows", "1" );
		TeleportEntity( skin, pos, ang, NULL_VECTOR );
		DispatchSpawn( skin );
		SetColor( skin, color, alpha );
	}
	return skin;
}

stock int CreateEnvSteam( int parent, float pos_local[3], float ang_local[3], int tail_color[3] )
{ 
	int  exaust = CreateEntityByName( "env_steam" );
	if ( exaust != -1 )
	{
		char ownName[32];
		FormatEx( ownName, sizeof( ownName ), "exaust_%d", exaust );
		DispatchKeyValue( exaust, "targetname", ownName );
		
		char parentName[32];
		GetEntityName( parent, parentName );
		DispatchKeyValue( exaust, "parentname", parentName );
		SetVariantString( parentName );
		AcceptEntityInput( exaust, "SetParent" );

		DispatchKeyValue( exaust, "spawnflags", "1" );
		DispatchKeyValue( exaust, "Type", "0" );
		DispatchKeyValue( exaust, "Spreadspeed", "10" );
		DispatchKeyValue( exaust, "Speed", "100" );		
		DispatchKeyValue( exaust, "Startsize", "3" );
		DispatchKeyValue( exaust, "EndSize", "7" );
		DispatchKeyValue( exaust, "JetLength", "10" );
		DispatchKeyValue( exaust, "Rate", "400" );
		
		char color[16];
		FormatEx( color, sizeof( color ), "%d %d %d", tail_color[0], tail_color[1], tail_color[2] );
		DispatchKeyValue( exaust, "rendercolor", color );
		DispatchKeyValue( exaust, "InitialState", "1" );
		DispatchKeyValue( exaust, "RenderAmt", "180" );
		DispatchSpawn( exaust );
		TeleportEntity( exaust, pos_local, ang_local, NULL_VECTOR );
		AcceptEntityInput( exaust, "TurnOn" );
	}
	return exaust;
}

stock int CreateThrust( int parent, float pos[3], float ang[3], float force )
{
	int thrust = CreateEntityByName( "phys_thruster" );
	if( thrust != -1 )
	{
		char spawnflags[16];
		FormatEx( spawnflags, sizeof( spawnflags ), "%i", 2 | 8 | 16 );		// Linear | Local | Ignore Mass
		DispatchKeyValue( thrust, "spawnflags", spawnflags );

		char frc[6];
		IntToString( RoundToCeil(force), frc, sizeof( frc ));
		DispatchKeyValue( thrust, "Force", frc );
		SetAttachment( thrust, parent );
		DispatchSpawn( thrust );
		TeleportEntity( thrust, pos, ang, NULL_VECTOR );
		AcceptEntityInput( thrust, "Activate" );
	}
	return thrust;
}

stock int CreateTorque( int parent, float pos[3], float ang[3], float force )
{
	int torque = CreateEntityByName( "phys_torque" ); // For rotation force
	if( torque != -1 )
	{
		char spawnflags[16];
		FormatEx( spawnflags, sizeof( spawnflags ), "%i", 4 | 8 | 16 );	// Torque(Rotation) | Local | Ignore Mass
		DispatchKeyValue( torque, "spawnflags", spawnflags );
		
		char frc[6];
		IntToString( RoundToCeil(force), frc, sizeof( frc ));
		DispatchKeyValue( torque, "Force", frc );
		SetAttachment( torque, parent );
		DispatchKeyValue( torque, "axis", "0 0 90" );
		DispatchSpawn( torque );
		TeleportEntity( torque, pos, ang, NULL_VECTOR );
		AcceptEntityInput( torque, "Activate" );
	}
	return torque;
}

stock int CreateUprightLifting( int parent, float pos[3], float ang[3] )
{
	int upright = CreateEntityByName( "phys_keepupright" );
	if( upright != -1 )
	{
		char upName[16];
		Format( upName, sizeof( upName ), "upright_%d", upright );
		DispatchKeyValue( upright, "targetname", upName );

		char parentName[32];
		GetEntityName( parent, parentName );
		DispatchKeyValue( upright, "targetentity", parentName );
		//SetVariantString( parentName );
		//AcceptEntityInput( upright, "SetParent" );
		SetAttachment( upright, parent );
		DispatchKeyValue( upright, "angularlimit", "30.0" );
		DispatchSpawn( upright);
		TeleportEntity( upright, pos, ang, NULL_VECTOR );
		ActivateEntity( upright );
		AcceptEntityInput( upright, "TurnOn" );
	}
	return upright;
}

stock int CreateUprightConstrain( int parent, float pos[3], float ang[3] )
{
	int upright = CreateEntityByName( "phys_ragdollconstraint" );
	if( upright != -1 )
	{
		DispatchKeyValue( upright, "spawnflags", "2" );
		DispatchKeyValue( upright, "ymin", "-50.0" );
		DispatchKeyValue( upright, "ymax", "50.0" );
		DispatchKeyValue( upright, "zmin", "-180.0" );
		DispatchKeyValue( upright, "zmax", "180.0" );
		DispatchKeyValue( upright, "xmin", "-50.0" );
		DispatchKeyValue( upright, "xmax", "50.0" );
		
		char parentName[32];
		GetEntityName( parent, parentName );
		DispatchKeyValue( upright, "attach1", parentName );
		
		DispatchSpawn( upright );
		ActivateEntity( upright );
		
		SetVariantString( parentName );
		AcceptEntityInput( upright, "SetParent" );
		TeleportEntity( upright, pos, ang, NULL_VECTOR );
	}
	return upright;
}

stock int CreatSound( int parent, const char[] sound_path )
{
	int sound = CreateEntityByName( "ambient_generic" );
	if( sound != -1 )
	{
		char nameSound[32];
		Format( nameSound, sizeof( nameSound ), "petsound_%d", sound );
		DispatchKeyValue( sound, "targetname", nameSound );
		
		char parentName[32];
		GetEntityName( parent, parentName );
		//SetVariantString( parentName );
		AcceptEntityInput( sound, "parentname", parentName );
		DispatchKeyValue( sound, "SourceEntityName", parentName );
		
		DispatchKeyValue( sound, "message", sound_path );
		DispatchKeyValue( sound, "radius", "1750.0" );
		DispatchKeyValue( sound, "spawnflags", "16" );
		AcceptEntityInput( sound, "Volume", "5.0" );
		AcceptEntityInput( sound, "Pitch", "45" );		

		DispatchSpawn( sound );
		AcceptEntityInput( sound, "PlaySound" );
	}
	return sound;
}

stock void SetThrusterTorque( int entity, float force )
{
	AcceptEntityInput( entity, "Deactivate" );
	char force_scale[16];
	IntToString( RoundToCeil(force), force_scale, sizeof( force_scale ));
	DispatchKeyValue( entity, "Force", force_scale );
	AcceptEntityInput( entity, "Activate" );
}

stock void GetLocalAttachmentPos( float angle_direction, float radius, float pos_output[3] )
{
	// calculate where the intersection between known radius and known angle. final result is new endpoint/pos_new
	pos_output[0] += radius * Cosine( DegToRad( angle_direction ));
	pos_output[1] += radius * Sine( DegToRad( angle_direction ));
}

stock int CreatEntAnimation( int parent, const char[] model, const char[] animation, float pos[3], float ang[3], float model_scale )
{
	int  entity = CreateEntityByName( "prop_dynamic_override" );
	if( entity != -1 )
	{
		char parentName[32];
		GetEntityName( parent, parentName );
		SetVariantString( parentName );
		AcceptEntityInput( entity, "SetParent" );
		
		DispatchKeyValue( entity, "model", model );
		//DispatchKeyValueVector( entity, "origin", pos );
		//DispatchKeyValueVector( entity, "Angles", ang );
		SetEntProp( entity, Prop_Send, "m_CollisionGroup", 1 );
		SetEntPropFloat( entity, Prop_Send,"m_flModelScale", model_scale );
		DispatchSpawn( entity );
		SetVariantString( animation );
		AcceptEntityInput( entity, "SetAnimation", -1, -1, 0 );
		TeleportEntity( entity, pos, ang, NULL_VECTOR );
	}
	return entity;
}

stock int CreatSprite( int parent, const char[] attachment, const char[] model, float pos[3], float ang[3], float model_scale )
{
	int sprite = CreateEntityByName( "env_sprite" );
	if( sprite != -1 )
	{
		if( !StrEqual( attachment, "none", false ))
		{
			SetVariantString( attachment );
			AcceptEntityInput( sprite, "SetParentAttachment" );
		}
		char parentName[32];
		GetEntityName( parent, parentName );
		SetVariantString( parentName );
		AcceptEntityInput( sprite, "SetParent" );
		
		DispatchKeyValue( sprite, "model", model );
		//DispatchKeyValue( sprite, "spawnflags", "3" );
		DispatchKeyValue( sprite, "spawnflags", "1" );
		DispatchKeyValue( sprite, "rendermode", "9" );
		DispatchKeyValueFloat( sprite, "scale", model_scale );
		DispatchSpawn( sprite );
		TeleportEntity( sprite, pos, ang, NULL_VECTOR );
	}
	return sprite;
}

stock int CreateGatlingGun( int parent, float pos[3], float ang[3], float damage, float radius )
{
	int gathlinggun = CreateEntityByName( "env_weaponfire" );
	if( gathlinggun != -1 )
	{
		char parentName[32];
		GetEntityName( parent, parentName );
		SetVariantString( parentName );
		AcceptEntityInput( gathlinggun, "SetParent" );
		DispatchKeyValue( gathlinggun, "parentname", parentName );
		DispatchKeyValueFloat( gathlinggun, "targetarc", radius );
		DispatchKeyValueFloat( gathlinggun, "targetrange", radius );
		DispatchKeyValueFloat( gathlinggun, "damagemod", damage );
		DispatchKeyValue( gathlinggun, "weapontype", "1" );
		DispatchKeyValue( gathlinggun, "targetteam", "3" );
		DispatchKeyValue( gathlinggun, "ignoreplayers", "1" );
		DispatchSpawn( gathlinggun );
		TeleportEntity( gathlinggun, pos, ang, NULL_VECTOR );
		AcceptEntityInput( gathlinggun, "Enable" );
	}
	return gathlinggun;
}

stock float AngleDifference( float angle1, float angle2 )
{
    int diff = ( RoundToCeil(angle2 - angle1) + 180 ) % 360 - 180;
    return float( diff < -180 ? diff + 360 : diff );
}

stock bool IsValidSurvivor( int client )
{
	return ( client > 0 && client <= MaxClients && IsClientConnected( client ) && IsClientInGame( client ) && GetClientTeam( client ) == 2 );
}

stock void GetEntOrigin( int entity, float pos_output[3], float mod_array_height )
{
	GetEntPropVector( entity, Prop_Send, "m_vecOrigin", pos_output );
	pos_output[2] += mod_array_height;
}

stock void GetEntAngle( int entity, float ang_output[3], float mod_array_val, int axis )
{
	GetEntPropVector( entity, Prop_Data, "m_angRotation", ang_output );
	ang_output[axis] += mod_array_val;
}

stock void SetOwner( int entity, int owner )
{
	SetEntPropEnt( entity, Prop_Data, "m_hOwnerEntity", owner );
}

stock int GetOwner( int entity )
{
	return GetEntPropEnt( entity, Prop_Data, "m_hOwnerEntity" );
}

stock void SetAttachment( int entity, int parent )
{
	SetEntPropEnt( entity, Prop_Data, "m_attachedObject", parent );
}

stock void SetArray3DFloat( float val_0, float val_1, float val_2, float array_output[3] )
{
	array_output[0] = val_0;
	array_output[1] = val_1;
	array_output[2] = val_2;
}

stock void AddValue3DFloat( float val_0, float val_1, float val_2, float array_output[3] )
{
	array_output[0] += val_0;
	array_output[1] += val_1;
	array_output[2] += val_2;
}

stock void CopyArray3DInt( int array_source[3], int array_output[3] )
{
	array_output[0] = array_source[0];
	array_output[1] = array_source[1];
	array_output[2] = array_source[2];
}

stock void Entity_Kill( int entity )
{
	AcceptEntityInput( entity, "Kill" );
}

stock void Entity_KillHierarchy( int entity )
{
	AcceptEntityInput( entity, "KillHierarchy" );
}

stock void Entity_KillClearParent( int entity )
{
	AcceptEntityInput( entity, "ClearParent" );
	RemoveEntity_KillHierarchy( entity );
}

stock void SetColor( int entity, int color[3], int alpha )
{
	SetEntityRenderMode( entity, RENDER_TRANSALPHA );
	SetEntityRenderColor( entity, color[0], color[1], color[2], alpha );
}

stock void SetGlow( int entity, int color[3], bool enable )
{
	int glowtype = 0;
	if( enable )
	{
		glowtype = 3;
	}
	int m_glowcolor = color[0] + ( color[1] * 256 ) + ( color[2] * 65536 );
	SetEntProp( entity, Prop_Send, "m_iGlowType", glowtype );
	SetEntProp( entity, Prop_Send, "m_nGlowRange", 0 );
	SetEntProp( entity, Prop_Send, "m_glowColorOverride", m_glowcolor );
}

stock void GetEntityName( int entity, char[] entity_name )
{
	GetEntPropString( entity, Prop_Data, "m_iName", entity_name, 32 );
}

stock int GetEntityParent( int entity )
{
	// get entity parent index
	return ( GetEntPropEnt( entity, Prop_Data, "m_hMoveParent" ));
}

stock int GetEntityChild( int entity )
{
	// get entity child index
	return ( GetEntPropEnt( entity, Prop_Data, "m_hMoveChild" ));
}

stock bool TraceRayGetEndpoint( float trace_pos_start[3], float trace_ang_start[3], any data, float trace_pos_output[3] )
{
	bool traced = false;
	Handle trace = TR_TraceRayFilterEx( trace_pos_start, trace_ang_start, MASK_SOLID_BRUSHONLY, RayType_Infinite, TraceEntityFilterPlayers, data );
	if( TR_DidHit( trace ))
	{ 
		// we just check if there is endpoint. we dont do any code inside trace function incase the code error, the Handle leaked.
		TR_GetEndPosition( trace_pos_output, trace );
		traced = true;
	}
	delete trace;
	return traced;
}

stock int TraceRayGetEntity( float trace_pos_start[3], float trace_ang_start[3], any data )
{
	int entity = -1;
	Handle trace = TR_TraceRayFilterEx( trace_pos_start, trace_ang_start, MASK_SOLID_BRUSHONLY, RayType_Infinite, TraceEntityFilterPlayers, data );
	if( TR_DidHit( trace ))
	{ 
		entity = TR_GetEntityIndex( trace );
	}
	delete trace;
	return entity;
}

stock bool TraceEntityFilterPlayers( int entity, int contentsMask, any data )
{
	return ( entity > 0 && entity != data );
}

stock int CreateEntity( const char[] ent_name, float pos[3], float ang[3] )
{
	int item = CreateEntityByName( ent_name );
	if( item != -1 )
	{
		DispatchKeyValueVector( item, "Origin", pos );
		DispatchKeyValueVector( item, "Angles", ang );
		DispatchSpawn( item );
	}
	return item;
}
