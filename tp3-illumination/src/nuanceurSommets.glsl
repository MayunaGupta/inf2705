
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

/////////////////////////////////////////////////////////////////

layout(location=0) in vec4 Vertex;
layout(location=2) in vec3 Normal;
layout(location=3) in vec4 Color;
layout(location=8) in vec4 TexCoord;


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

void main( void )
{
   // transformation standard du sommet
   gl_Position = matrProj * matrVisu * matrModel * Vertex;

   vec3 pos = vec3( matrVisu * matrModel * Vertex );
   

   vec4 CoColor = FrontMaterial.emission + FrontMaterial.ambient * LightModel.ambient;

   AttribsOut.couleur= CoColor;
   AttribsOut.texCoord=TexCoord.st;
   // couleur du sommet
   //
   AttribsOut.normale = matrNormale * Normal;
   AttribsOut.obsVec = normalize(-pos); 

   for(int i=0;i<2;i++){

      AttribsOut.lightVec[i] = ( matrVisu * LightSource.position[i] ).xyz - pos;
      AttribsOut.spotDir[i] = transpose(inverse(mat3(matrVisu ))) *(-LightSource.spotDirection[i]);
      AttribsOut.couleur += calculerReflexion( AttribsOut.lightVec[i], AttribsOut.normale, AttribsOut.obsVec, AttribsOut.spotDir[i]);


      //float spotFactor= calculerSpot(AttribsOut.spotDir[i] , AttribsOut.lightVec[i]);
     // AttribsOut.couleur= AttribsOut.couleur*spotFactor;
      
   }
   

}
