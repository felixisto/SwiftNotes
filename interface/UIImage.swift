
import UIKit

struct UIImageManipulation
{
    func convertToJPG(image: UIImage) -> UIImage?
    {
        if let data = image.jpegData(compressionQuality: 1.0)
        {
            return UIImage(data: data)
        }
        
        return nil
    }
    
    func resizeImage(image: UIImage, newWidth: CGFloat) -> UIImage?
    {
        let scale = newWidth / image.size.width
        let newHeight = image.size.height * scale
        
        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
        
        image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight), blendMode: .normal, alpha: 1.0)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return newImage
    }
}

struct UIImageColorUtilities
{
    func getPixelColor(image: UIImage, pos: CGPoint) -> UIColor?
    {
        guard let imageData = image.cgImage?.dataProvider?.data else {
            return nil
        }
        
        guard let pixelData = CGDataProvider(data: imageData)?.data else {
            return nil
        }
        
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        
        let pixelInfo: Int = ((Int(image.size.width) * Int(pos.y)) + Int(pos.x)) * 4
        
        let r = CGFloat(data[pixelInfo]) / CGFloat(255.0)
        let g = CGFloat(data[pixelInfo+1]) / CGFloat(255.0)
        let b = CGFloat(data[pixelInfo+2]) / CGFloat(255.0)
        
        return UIColor(red: r, green: g, blue: b, alpha: 1.0)
    }
    
    func blendColors(c1: UIColor, c2: UIColor, alpha: Double) -> UIColor
    {
        var a = CGFloat(alpha)
        
        a = min(1.0, max(0.0, a))
        
        let beta = 1.0 - a
        
        var r1 : CGFloat = 0
        var g1 : CGFloat = 0
        var b1 : CGFloat = 0
        var a1 : CGFloat = 0
        var r2 : CGFloat = 0
        var g2 : CGFloat = 0
        var b2 : CGFloat = 0
        var a2 : CGFloat = 0
        
        c1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        c2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        
        let r = r1 * beta + r2 * a
        let g = g1 * beta + g2 * a
        let b = b1 * beta + b2 * a
        
        return UIColor(red: r, green: g, blue: b, alpha: 1.0)
    }
    
    func averageColor(image: UIImage) -> UIColor?
    {
        let rawImageRef : CGImage = image.cgImage!
        
        guard let dataProvider = rawImageRef.dataProvider else {
            return nil
        }
        
        guard let data = dataProvider.data else {
            return nil
        }
        
        let rawPixelData = CFDataGetBytePtr(data);
        
        let imageHeight = rawImageRef.height
        let imageWidth  = rawImageRef.width
        let bytesPerRow = rawImageRef.bytesPerRow
        let stride = rawImageRef.bitsPerPixel / 6
        
        var red : CGFloat = 0
        var green : CGFloat = 0
        var blue : CGFloat = 0
        
        for row in 0...imageHeight {
            var rowPtr = rawPixelData! + (bytesPerRow * row)
            for _ in 0...imageWidth {
                red    += CGFloat(rowPtr[0])
                green  += CGFloat(rowPtr[1])
                blue   += CGFloat(rowPtr[2])
                rowPtr += Int(stride)
            }
        }
        
        let f : CGFloat = 1.0 / (255.0 * CGFloat(imageWidth) * CGFloat(imageHeight))
        
        return UIColor(red: f * red, green: f * green, blue: f * blue , alpha: 1.0)
    }
    
    func mostCommonColor(image: UIImage) -> UIColor?
    {
        let rawImageRef : CGImage = image.cgImage!
        guard let dataProvider = rawImageRef.dataProvider else {
            return nil
        }
        guard let data = dataProvider.data else {
            return nil
        }
        
        let rawPixelData = CFDataGetBytePtr(data);
        
        let imageHeight = rawImageRef.height
        let imageWidth  = rawImageRef.width
        let bytesPerRow = rawImageRef.bytesPerRow
        let stride = rawImageRef.bitsPerPixel / 6
        
        var colors : [String : Int] = [:]
        
        for row in 0...imageHeight {
            var rowPtr = rawPixelData! + (bytesPerRow * row)
            for _ in 0...imageWidth {
                let red = Int(rowPtr[0])
                let green = Int(rowPtr[1])
                let blue = Int(rowPtr[2])
                let stringFromColor = String(format: "%0.3d%0.3d%0.3d", red, green, blue)
                
                if let entry = colors[stringFromColor]
                {
                    colors[stringFromColor] = entry + 1
                }
                else
                {
                    colors[stringFromColor] = 1
                }
                
                rowPtr += Int(stride)
            }
        }
        
        let blackColorAsString = "000000000"
        var mostCommonColor = blackColorAsString
        var mostCommonColorCount = 0
        
        for entry in colors
        {
            if entry.value > mostCommonColorCount
            {
                mostCommonColor = entry.key
                mostCommonColorCount = entry.value
            }
        }
        
        let red = Int(mostCommonColor[String.Index(encodedOffset: 0)...String.Index(encodedOffset: 2)])
        let green = Int(mostCommonColor[String.Index(encodedOffset: 3)...String.Index(encodedOffset: 5)])
        let blue = Int(mostCommonColor[String.Index(encodedOffset: 6)...String.Index(encodedOffset: 8)])
        
        if red != nil && green != nil && blue != nil
        {
            return UIColor(red: CGFloat(red!), green: CGFloat(green!), blue: CGFloat(blue!), alpha: 1)
        }
        
        return nil
    }
}
