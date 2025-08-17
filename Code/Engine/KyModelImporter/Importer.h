/*
    This code is part of Kyshutsu Engine.

    Copyright (c) 2020-2025 WD Studios Corp. and/or its licensors. All rights reserved in
    all media. The coded instructions, statements, computer programs, and/or related
    material (collectively the "Data") in these files are under the MIT License.
*/
#pragma once
#include <KyKernel/Meshes/MeshBufferUtils.h>
#include <KyModelImporter/KyModelImporterDLL.h>

#include <rtm/types.h>

namespace kyshutsu
{
  enum AdditiveReference
  {
    FirstKeyFrame,
    LastKeyFrame,
  };

  struct ImportOptions
  {
    nsString m_sSourceFile;

    bool m_bImportSkinningData = false;
    bool m_bRecomputeNormals = false;
    bool m_bRecomputeTangents = false;
    bool m_bNormalizeWeights = false;
    rtm::matrix3x3f m_RootTransform;

    // if non-empty, only import meshes whose names start or end with any of these strings
    nsDynamicArray<nsString> m_MeshIncludeTags;
    // if non-empty, do not import meshes whose names start or end with any of these
    // strings (unless already explicitly included)
    nsDynamicArray<nsString> m_MeshExcludeTags;
    // TODO: Replace this with kyshutsu's version.
    // nsMeshResourceDescriptor* m_pMeshOutput = nullptr;
    nsEnum<kyMeshNormalPrecision> m_MeshNormalsPrecision = kyMeshNormalPrecision::Default;
    nsEnum<kyMeshTexCoordPrecision> m_MeshTexCoordsPrecision
      = kyMeshTexCoordPrecision::Default;
    nsEnum<kyMeshBoneWeigthPrecision> m_MeshBoneWeightPrecision
      = kyMeshBoneWeigthPrecision::Default;
    nsEnum<kyMeshVertexColorConversion> m_MeshVertexColorConversion
      = kyMeshVertexColorConversion::Default;
    // TODO: Replace this with kyshutsu's version.
    // nsEditableSkeleton* m_pSkeletonOutput = nullptr;

    bool m_bAdditiveAnimation = false;
    AdditiveReference m_AdditiveReference = AdditiveReference::FirstKeyFrame;

    nsString
      m_sAnimationToImport; // empty = first in file; "name" = only anim with that name
    // TODO: Replace this with kyshutsu's version.
    // nsAnimationClipResourceDescriptor* m_pAnimationOutput = nullptr;
    nsUInt32 m_uiFirstAnimKeyframe = 0;
    nsUInt32 m_uiNumAnimKeyframes = 0;

    nsUInt8 m_uiMeshSimplification = 0;
    nsUInt8 m_uiMaxSimplificationError = 5;
    bool m_bAggressiveSimplification = false;

    // Adjustments to deal with bad data:
    float m_fAnimationPositionScale = 1.0f;
  };

  enum class PropertySemantic : nsInt8
  {
    Unknown = 0,

    DiffuseColor,
    RoughnessValue,
    MetallicValue,
    EmissiveColor,
    TwosidedValue,
  };

  enum class TextureSemantic : nsInt8
  {
    Unknown = 0,

    DiffuseMap,
    DiffuseAlphaMap,
    OcclusionMap,
    RoughnessMap,
    MetallicMap,
    OrmMap,
    DisplacementMap,
    NormalMap,
    EmissiveMap,
  };

  struct NS_KYMODELIMP_DLL OutputTexture
  {
    nsString m_sFilename;
    nsString m_sFileFormatExtension;
    nsConstByteArrayPtr m_RawData;

    void GenerateFileName(nsStringBuilder& out_sName) const;
  };

  struct NS_KYMODELIMP_DLL OutputMaterial
  {
    nsString m_sName;

    nsInt32 m_iReferencedByMesh
      = -1; // if -1, no sub-mesh in the output actually references this
    nsMap<TextureSemantic, nsString> m_TextureReferences; // semantic -> path
    nsMap<PropertySemantic, nsVariant> m_Properties;      // semantic -> value
  };

  /*
   * @author Mikael K. Aboagye
   * @brief Model Import Interface System for importing models into the Kyshutsu Engine.
   */
  class NS_KYMODELIMP_DLL KyImporter
  {
    NS_DISALLOW_COPY_AND_ASSIGN(KyImporter);

  public:
    nsResult Import(const ImportOptions& options, nsLogInterface* pLogInterface = nullptr,
      nsProgress* pProgress = nullptr);
    const ImportOptions& GetImportOptions() const { return m_Options; }

    nsMap<nsString, OutputTexture> m_OutputTextures; // path -> additional data
    nsDeque<OutputMaterial> m_OutputMaterials;
    nsDynamicArray<nsString> m_OutputAnimationNames;
    nsDynamicArray<nsString> m_OutputMeshNames;

  protected:
    virtual nsResult DoImport() = 0;

    ImportOptions m_Options;
    nsProgress* m_pProgress = nullptr;
  };

} // namespace kyshutsu