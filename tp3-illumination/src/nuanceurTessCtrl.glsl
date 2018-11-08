
#version 410
// Définition des paramètres des sources de lumière



/////////////////////////////////////////////////////////////////
layout(vertices = 4) out;
//in int gl_InvocationID;
//in vec3 gl_TessCoord;
//in int gl_PatchVerticesIn;
///in int gl_PrimitiveID;

//patch in float gl_TessLevelOuter[4];

//patch in float gl_TessLevelInner[2];

uniform float TessLevelInner;
uniform float TessLevelOuter;


in Attribs {
   vec4 couleur;
   vec3 normale;
   vec3 obsVec;
   vec3 lightVec[2];
   vec3 spotDir[2];
   vec2 texCoord;
} AttribsIn[];

out Attribs {
   vec4 couleur;
   vec3 normale;
   vec3 obsVec;
   vec3 lightVec[2];
   vec3 spotDir[2];
   vec2 texCoord;
} AttribsOut[];


void main()
{
   gl_out[gl_InvocationID].gl_Position = gl_in[gl_InvocationID].gl_Position;

   if ( gl_InvocationID == 0 )
   {
      gl_TessLevelInner[0] = TessLevelInner;
      gl_TessLevelInner[1] = TessLevelInner;
      gl_TessLevelOuter[0] = TessLevelOuter;
      gl_TessLevelOuter[1] = TessLevelOuter;
      gl_TessLevelOuter[2] = TessLevelOuter;
      gl_TessLevelOuter[3] = TessLevelOuter;
   }

   AttribsOut[gl_InvocationID].couleur = AttribsIn[gl_InvocationID].couleur;
}



