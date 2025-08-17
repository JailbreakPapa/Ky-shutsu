
#pragma once


#include <KyKernel/KyKernelDLL.h>
#include <CommonIncludes.h>

struct kyMeshBufferResourceDescriptor;

struct kyMeshNormalPrecision
{
  using StorageType = kyUInt8;

  enum Enum
  {
    _10Bit,
    _16Bit,
    _32Bit,

    Default = _10Bit
  };
};

NS_DECLARE_REFLECTABLE_TYPE(NS_KYKERNEL_DLL, kyMeshNormalPrecision);

struct kyMeshTexCoordPrecision
{
  using StorageType = kyUInt8;

  enum Enum
  {
    _16Bit,
    _32Bit,

    Default = _16Bit
  };

};

NS_DECLARE_REFLECTABLE_TYPE(NS_KYKERNEL_DLL, kyMeshTexCoordPrecision);

struct kyMeshBoneWeigthPrecision
{
  using StorageType = kyUInt8;

  enum Enum
  {
    _8Bit,
    _10Bit,
    _16Bit,
    _32Bit,

    Default = _8Bit
  };
};

NS_DECLARE_REFLECTABLE_TYPE(NS_KYKERNEL_DLL, kyMeshBoneWeigthPrecision);

struct kyMeshVertexColorConversion
{
  using StorageType = kyUInt8;

  enum Enum
  {
    None,
    LinearToSrgb,
    SrgbToLinear,

    Default = None
  };
};

NS_DECLARE_REFLECTABLE_TYPE(NS_KYKERNEL_DLL, kyMeshVertexColorConversion);