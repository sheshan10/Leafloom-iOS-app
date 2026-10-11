export const MAX_IMAGE_BYTES = 15 * 1024 * 1024;
const MAX_DIMENSION = 1024;

export class ImageLoadError extends Error {}

/**
 * Reads a user-selected file, rejects non-images and very large files, and downsamples it to at most
 * 1024px on the long edge as a JPEG data URL. This mirrors the native ImageStore downsampling so
 * stored photos stay small.
 */
export const fileToDownsampledDataUrl = async (file: File): Promise<string> => {
  if (!file.type.startsWith('image/')) throw new ImageLoadError('That file is not an image. Choose a JPEG, PNG or HEIC photo.');
  if (file.size > MAX_IMAGE_BYTES) throw new ImageLoadError('That photo is larger than 15 MB. Choose a smaller image.');

  const url = URL.createObjectURL(file);
  try {
    const img = await new Promise<HTMLImageElement>((resolve, reject) => {
      const el = new Image();
      el.onload = () => resolve(el);
      el.onerror = () => reject(new ImageLoadError('This image could not be read. It may be corrupted or in an unsupported format.'));
      el.src = url;
    });
    const scale = Math.min(1, MAX_DIMENSION / Math.max(img.naturalWidth, img.naturalHeight));
    const canvas = document.createElement('canvas');
    canvas.width = Math.max(1, Math.round(img.naturalWidth * scale));
    canvas.height = Math.max(1, Math.round(img.naturalHeight * scale));
    const ctx = canvas.getContext('2d');
    if (!ctx) throw new ImageLoadError('This browser cannot process images.');
    ctx.drawImage(img, 0, 0, canvas.width, canvas.height);
    return canvas.toDataURL('image/jpeg', 0.82);
  } finally {
    URL.revokeObjectURL(url);
  }
};
