import { BigNumberish } from 'ethers';
import { hexConcat, hexlify, hexZeroPad } from 'ethers/lib/utils';

/**
 * @description get catalog part id in lightm recommended way: https://lightm.notion.site/Recommended-allocation-way-for-Part-ID-of-Catalog-1e471ff9f38f49c191f68db6845bc353
 * @param classId
 * @param id
 * @param type
 * @returns partId
 */
export function getCatalogPartId(classId: BigNumberish, id: BigNumberish, type: 0 | 1) {
  const _classId = hexZeroPad(hexlify(classId), 2);
  const _id = hexZeroPad(hexlify(id), 4);
  const _typeAndReserved = hexConcat([hexlify(type * 2 ** 7), hexlify(0)]);

  const partId = hexConcat([_classId, _id, _typeAndReserved]);

  return partId;
}
