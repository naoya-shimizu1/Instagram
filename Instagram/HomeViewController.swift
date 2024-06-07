//
//  HomeViewController.swift
//  Instagram
//
//  Created by PC-SYSKAI555 on 2024/05/10.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

extension HomeViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // セルを取得してデータを設定する
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! PostTableViewCell

        cell.setPostData(posts[indexPath.row])
        
        // セル内のボタンのアクションをソースコードで設定する
        // likeボタン押下時
        cell.likeButton.addTarget(self, action: #selector(handleLikeButton(_:)), for: .touchUpInside)
        
        // コメント入力ボタン押下時
        cell.commentButton.addTarget(self, action: #selector(handleCommentButton(_:)), for: .touchUpInside)
        
        return cell
    }
    
    @objc func handleLikeButton(_ sender: UIButton) {
        print("DEBUG_PRINT: likeボタンがタップされました。")

        // タップされたセルのインデックスを求める
        let point = sender.convert(CGPoint.zero, to: tableView)
        let indexPath = tableView.indexPathForRow(at: point)
        
        // 配列からタップされたインデックスのデータを取り出す
        let postData = posts[indexPath!.row]
        
        // likesを更新する
        if let myid = Auth.auth().currentUser?.uid {
            // 更新データを作成する
            var updateValue: FieldValue
            if postData.isLiked {
                // すでにいいねをしている場合は、いいね解除のためmyidを取り除く更新データを作成
                updateValue = FieldValue.arrayRemove([myid])
            } else {
                // 今回新たにいいねを押した場合は、myidを追加する更新データを作成
                updateValue = FieldValue.arrayUnion([myid])
            }
            // likesに更新データを書き込む
            let postRef = Firestore.firestore().collection(Const.PostPath).document(postData.id)
            postRef.updateData(["likes": updateValue])
        }
    }
    
    @objc func handleCommentButton(_ sender: UIButton) {
        print("DEBUG_PRINT: commentボタンがタップされました。")
        
        // タップされたセルのインデックスを求める
        let point = sender.convert(CGPoint.zero, to: tableView)
        let indexPath = tableView.indexPathForRow(at: point)
        
        // 配列からタップされたインデックスのデータを取り出す
        let postData = posts[indexPath!.row]
        
        //postData.idを渡して、コメント入力画面に遷移
        let commentViewController = storyboard!.instantiateViewController(withIdentifier: "Comment") as! CommentViewController
        
        commentViewController.postDataId = postData.id
        // モーダルを全画面表示にして、ViewWillAppearが反応するようにする
        commentViewController.modalPresentationStyle = .fullScreen
        
        self.present(commentViewController, animated: true, completion: nil)
    }
}

class HomeViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    // 投稿データを格納する配列
    var posts: [PostData] = []
    
    // Firestoreのリスナー
    var postListener: ListenerRegistration?
    var commentListener: ListenerRegistration?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        tableView.delegate = self
        tableView.dataSource = self
        
        // カスタムセルを登録する
        let nib = UINib(nibName: "PostTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "Cell")
        // カスタムセルの高さは、コメント量に応じて自動調節する
        tableView.rowHeight = UITableView.automaticDimension
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("DEBUG_PRINT: viewWillAppear")
        // ログイン済みか確認
        if Auth.auth().currentUser != nil {
            // listenerを登録して投稿データの更新を監視する
            let postsRef = Firestore.firestore().collection(Const.PostPath).order(by: "date", descending: true)
            //let commentsRef = Firestore.firestore().collection(Const.CommentPath)
            
            postListener = postsRef.addSnapshotListener() { (querySnapshot, error) in
                if let error = error {
                    print("DEBUG_PRINT: snapshotの取得が失敗しました。 \(error)")
                    return
                }
                // 取得したdocumentをもとにPostDataを作成し、postsの配列にする。
                self.posts = querySnapshot!.documents.map { document in
                    let postData = PostData(document: document)
                    print("DEBUG_PRINT: \(postData)")
                    return postData
                }
                // TableViewの表示を更新する
                self.tableView.reloadData()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("DEBUG_PRINT: viewWillDisapper")
        // listenerを削除して監視を停止する
        postListener?.remove()
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
