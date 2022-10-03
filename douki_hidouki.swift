// 普通の非同期処理と
// URLを指定して画像をダウンロードする
func downloadImage(url: URL, completion: (UIImage?, Error?) -> ()) {
    let ref = Storage.storage().reference(withPath: "path/to/image.jpg")
    let task = ref.write(toFile: URL(fileURLWithPath: "path/to/image.jpg"))

    // ブログレス処理
    task.observe(.progress) { _ in
        // ブログレス処理(割愛)
    }
    // 失敗時
    task.observe(.failure) { snapshot in
        task.cancel()
        completion(nil, snapshot.error)
    }
    // 成功時
    task.observe(.success) { _ in
        let image: UIImage = // ダウンロードした画像を撮ってくる処理は割愛
        completion(image, nil)
    }
}
/***************************************************************************/
// DispatchSemaphore
func downloadImage(url: URL) -> UIImage? {
    let semaphore = DispatchSemaphore(value: 0) // セマフォ変数
    var imageOrNil: UIImage?

    let ref = Storage.storage().reference(withPath: "path/to/image.jpg")
    let task = ref.write(toFile: URL(fileURLWithPath: "path/to/image.jpg"))

    task.observe(.progress) { _ in
        // ブログレス処理(割愛)
    }
    task.observe(.failure) { snapshot in
        task.cancel()
        semaphore.signal()
    }
    task.observe(.success) { _ in
        imageOrNil = // ダウンロードした画像を撮ってくる処理は割愛
        semaphore.signal()
    }

    semaphore.wait()
    return imageOrNil
}

// 呼び出し側
if let downloadUrl = self.requestImageDownloadUrl() {
    if let downloadedImage = self.downloadImage(url: downloadUrl) {
        if let processedImage = self.processImage(downloadedImage) {
            if let uploadUrl = self.requestImageUploadUrl() {
                self.uploadImage(image: processedImage, to url: uploadUrl)
            }
        }
    }// ネスト地獄になってしまう

/***************************************************************************/
// throwを取り込んだやり方
func downloadImage(url: URL) throws -> UIImage  {
    let semaphore = DispatchSemaphore(value: 0)
    var errorOrNil: Error?
    var image: UIImage!

    let ref = Storage.storage().reference(withPath: "path/to/image.jpg")
    let task = ref.write(toFile: URL(fileURLWithPath: "path/to/image.jpg"))

    task.observe(.progress) { _ in
        // ブログレス処理(割愛)
    }
    task.observe(.failure) { snapshot in
        task.cancel()
        errorOrNil = snapshot.error
        semaphore.signal()
    }
    task.observe(.success) { _ in
        image = // ダウンロードした画像を撮ってくる処理は割愛
        semaphore.signal()
    }

    semaphore.wait()
    if let error = errorOrNil {
        throw error
    }
    return image
}

//呼び出し側
do {
    let downloadUrl = try self.requestImageDownloadUrl()
    let downloadedImage = try self.downloadImage(url: downloadUrl)
    let processedImage = try self.processImage(downloadedImage)
    let uploadUrl = try self.requestImageUploadUrl()
    try self.uploadImage(image: processedImage, to url: uploadUrl)
} catch {
    // エラー処理
}
