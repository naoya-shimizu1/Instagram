//
//  CommentViewController.swift
//  Instagram
//
//  Created by PC-SYSKAI555 on 2024/05/21.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import SVProgressHUD

class CommentViewController: UIViewController {
    
    @IBOutlet weak var commentTextView: UITextView!
    // ホーム画面から受け取るデータを格納
    var postDataId: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // ホーム画面から受け取ったデータをコンソールに表示
        print(self.postDataId!)

        // Do any additional setup after loading the view.
        // 枠のカラー
        commentTextView.layer.borderColor = UIColor.black.cgColor
        
        // 枠の幅
        commentTextView.layer.borderWidth = 1.0
        
        // 枠を角丸にする
        commentTextView.layer.cornerRadius = 20.0
        commentTextView.layer.masksToBounds = true
        
        // 背景をタップしたらdismissKeyboardメソッドを呼ぶように設定する
        let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target:self, action:#selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tapGesture)
    }
    
    @objc func dismissKeyboard() {
        // キーボードを閉じる
        view.endEditing(true)
    }
    
    @IBAction func handleSendButton(_ sender: Any) {
        // コメント入力者名を取得
        let name = Auth.auth().currentUser?.displayName
        // 既存のコメント全文格納用
        var comment = ""
        // コメント格納パスの定義
        let commentRef = Firestore.firestore().collection(Const.PostPath).document(postDataId)
        
        // HUDで投稿処理中の表示を開始
        SVProgressHUD.show()
        
        // 既存のコメント全文を取得
        Task {
            do {
                let document = try await commentRef.getDocument()
                if document.exists {
                    let dataDescription = document.data().map(String.init(describing:)) ?? "nil"
                    print("Document data: \(dataDescription)")
                    
                    let postDic = document.data()
                    
                    if let postDic = postDic {
                        if postDic["comment"] != nil {
                            comment = postDic["comment"] as! String
                        }
                    }
                    // 入力されたコメントと既存のコメントを連結
                    let result = (comment + "\n" + "\n" + self.commentTextView.text! + "(" + name! + ")")
                    
                    do {
                        try await commentRef.updateData([
                            "comment": result
                        ])
                        print("Document successfully updated")
                        // HUDで投稿完了を表示する
                        SVProgressHUD.showSuccess(withStatus: "コメントしました")
                        // 投稿処理が完了したので先頭画面に戻る
                        self.view.window?.rootViewController?.dismiss(animated: true, completion: nil)
                    } catch {
                      print("Error updating document: \(error)")
                    }
                } else {
                    print("Document does not exist")
                }
            } catch {
                print("Error getting document: \(error)")
            }
        }
    }
    
    @IBAction func handleCancelButton(_ sender: Any) {
        // 画面を閉じる
        self.dismiss(animated: true, completion: nil)
    }
    
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
