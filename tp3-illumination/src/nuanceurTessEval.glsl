#version 410

// Définition des paramètres des sources de lumière
layout (std140) uniform LightSourceParameters
{
   vec4 ambient;
   vec4 diffuse;
   vec4 specular;
   vec4 position[2];      // dans le repère du monde
   vec3 spotDirection[2]; // dans le repère du monde
   float spotExponent;
   float spotAngleOuverture; // ([0.0,90.0] ou 180.0)
   float constantAttenuation;
   float linearAttenuation;
   float quadraticAttenuation;
} LightSource;

// Définition des paramètres des matériaux
layout (std140) uniform MaterialParameters
{
   vec4 emission;
   vec4 ambient;
   vec4 diffuse;
   vec4 specular;
   float shininess;
} FrontMaterial;

// Définition des paramètres globaux du modèle de lumière
layout (std140) uniform LightModelParameters
{
   vec4 ambient;       // couleur ambiante
   bool localViewer;   // observateur local ou à l'infini?
   bool twoSide;       // éclairage sur les deux côtés ou un seul?
} LightModel;

layout (std140) uniform varsUnif
{
   // partie 1: illumination
   int typeIllumination;     // 0:Gouraud, 1:Phong
   bool utiliseBlinn;        // indique si on veut utiliser modèle spéculaire de Blinn ou Phong
   bool utiliseDirect;       // indique si on utilise un spot style Direct3D ou OpenGL
   bool afficheNormales;     // indique si on utilise les normales comme couleurs (utile pour le débogage)
   // partie 3: texture
   int texnumero;            // numéro de la texture appliquée
   bool utiliseCouleur;      // doit-on utiliser la couleur de base de l'objet en plus de celle de la texture?
   int afficheTexelFonce;    // un texel noir doit-il être affiché 0:noir, 1:mi-coloré, 2:transparent?
};

uniform mat4 matrModel;
uniform mat4 matrVisu;
uniform mat4 matrProj;
uniform mat3 matrNormale;

//==========================================================

layout(quads) in;

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
} AttribsOut;

float calculerSpot( in vec3 D, in vec3 L )
{
   float spotFactor = 0.0;
   float cos_delta= cos(radians(LightSource.spotAngleOuverture));
   float cos_inner= cos_delta;
   float cos_outer= pow(cos_delta, 1.01 + 0.5 * LightSource.spotExponent);
   float cos_gamma= max( dot( normalize( L),normalize( D) ), 0.0 ); 
   
   if (cos_gamma > cos_delta){

      //opengl or direct 3d
      spotFactor= utiliseDirect ? pow(cos_gamma,LightSource.spotExponent) : smoothstep ( cos_outer, cos_inner , cos_gamma );   
   }
  

   return( spotFactor );
}
vec4 calculerReflexion( in vec3 L, in vec3 N, in vec3 O, in vec3 D)
{  
   vec4 newColor = vec4(0.0);
   newColor += FrontMaterial.ambient * LightSource.ambient;
   // produit scalaire pour la réflexion spéculaire
   float NdotHV = max( dot( normalize( L + O ), N), 0.0 );

   newColor += FrontMaterial.diffuse * LightSource.diffuse * max(0.0,dot(N,L));
   // composante spéculaire
   
   newColor += FrontMaterial.specular * LightSource.specular * pow(NdotHV, FrontMaterial.shininess);
   // composante ambiante
   

   newColor *= calculerSpot(D,L);
   newColor = (!utiliseCouleur) ? vec4( 0.2, 0.2, 0.2, 1.0 ) : newColor;
   return( newColor );
}



float interpole( float v0, float v1, float v2, float v3 )
{
   // mix( x, y, f ) = x * (1-f) + y * f.
   float v01 = mix( v0, v1, gl_TessCoord.x );
   float v32 = mix( v3, v2, gl_TessCoord.x );
   return mix( v01, v32, gl_TessCoord.y );
}
vec2 interpole( vec2 v0, vec2 v1, vec2 v2, vec2 v3 )
{
   // mix( x, y, f ) = x * (1-f) + y * f.
   vec2 v01 = mix( v0, v1, gl_TessCoord.x );
   vec2 v32 = mix( v3, v2, gl_TessCoord.x );
   return mix( v01, v32, gl_TessCoord.y );
}
vec3 interpole( vec3 v0, vec3 v1, vec3 v2, vec3 v3 )
{
   // mix( x, y, f ) = x * (1-f) + y * f.
   vec3 v01 = mix( v0, v1, gl_TessCoord.x );
   vec3 v32 = mix( v3, v2, gl_TessCoord.x );
   return mix( v01, v32, gl_TessCoord.y );
}
vec4 interpole( vec4 v0, vec4 v1, vec4 v2, vec4 v3 )
{
   // mix( x, y, f ) = x * (1-f) + y * f.
   vec4 v01 = mix( v0, v1, gl_TessCoord.x );
   vec4 v32 = mix( v3, v2, gl_TessCoord.x );
   return mix( v01, v32, gl_TessCoord.y );
}

void main()
{
   
   vec4 Vertex  = interpole( gl_in[0].gl_Position, gl_in[1].gl_Position, gl_in[3].gl_Position, gl_in[2].gl_Position );

   gl_Position = matrProj * matrVisu * Vertex;


   vec3 pos = vec3( matrVisu * Vertex );

   AttribsOut.normale = interpole( AttribsIn[0].normale, AttribsIn[1].normale, AttribsIn[3].normale, AttribsIn[2].normale );
   
   AttribsOut.texCoord = interpole( AttribsIn[0].texCoord, AttribsIn[1].texCoord, AttribsIn[3].texCoord, AttribsIn[2].texCoord );

   AttribsOut.obsVec = normalize(-pos);   
   
   vec4 CoColor = FrontMaterial.emission + FrontMaterial.ambient * LightModel.ambient;

   AttribsOut.couleur= CoColor;


   for(int i=0;i<2;i++){

    
      AttribsOut.lightVec[i] = ( matrVisu * LightSource.position[i] ).xyz - pos;
      AttribsOut.spotDir[i] = transpose(inverse(mat3(matrVisu ))) *(-LightSource.spotDirection[i]);
      AttribsOut.couleur += calculerReflexion( normalize(AttribsOut.lightVec[i]), normalize(AttribsOut.normale), normalize(AttribsOut.obsVec), normalize(AttribsOut.spotDir[i]));
     // AttribsOut.couleur += vec4(0.75);

      
   }
   
}
