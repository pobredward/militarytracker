import { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  FlatList,
  TouchableOpacity,
  TextInput,
  Modal,
  Alert,
  ActivityIndicator,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useAuthStore } from '../../src/stores/authStore';
import { getPosts, createPost, toggleLike, deletePost } from '../../src/services/communityService';
import { Colors } from '../../src/utils/colors';
import { formatDate } from '../../src/utils/formatters';
import { Post } from '../../src/types';

function PostCard({
  post,
  currentUserId,
  onLike,
  onDelete,
}: {
  post: Post;
  currentUserId: string;
  onLike: () => void;
  onDelete: () => void;
}) {
  const liked = post.likes.includes(currentUserId);
  const isOwner = post.userId === currentUserId;

  return (
    <View style={styles.postCard}>
      <View style={styles.postHeader}>
        <View style={styles.avatar}>
          <Text style={styles.avatarText}>{post.authorName[0]?.toUpperCase() ?? '?'}</Text>
        </View>
        <View style={{ flex: 1 }}>
          <Text style={styles.authorName}>{post.authorName}</Text>
          <Text style={styles.postDate}>{formatDate(post.createdAt)}</Text>
        </View>
        {isOwner && (
          <TouchableOpacity onPress={onDelete}>
            <Text style={styles.deleteBtn}>삭제</Text>
          </TouchableOpacity>
        )}
      </View>
      <Text style={styles.postTitle}>{post.title}</Text>
      <Text style={styles.postContent} numberOfLines={3}>
        {post.content}
      </Text>
      <View style={styles.postFooter}>
        <TouchableOpacity style={styles.likeBtn} onPress={onLike}>
          <Text style={styles.likeEmoji}>{liked ? '❤️' : '🤍'}</Text>
          <Text style={[styles.likeCount, liked && { color: Colors.danger }]}>
            {post.likes.length}
          </Text>
        </TouchableOpacity>
        <View style={styles.commentBadge}>
          <Text style={styles.commentEmoji}>💬</Text>
          <Text style={styles.commentCount}>{post.commentCount}</Text>
        </View>
      </View>
    </View>
  );
}

export default function CommunityScreen() {
  const { user } = useAuthStore();
  const [posts, setPosts] = useState<Post[]>([]);
  const [loading, setLoading] = useState(false);
  const [modalVisible, setModalVisible] = useState(false);
  const [title, setTitle] = useState('');
  const [content, setContent] = useState('');
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    loadPosts();
  }, []);

  async function loadPosts() {
    setLoading(true);
    try {
      const data = await getPosts(20);
      setPosts(data);
    } finally {
      setLoading(false);
    }
  }

  async function handleSubmit() {
    if (!user || !title.trim() || !content.trim()) {
      Alert.alert('입력 오류', '제목과 내용을 모두 입력해주세요.');
      return;
    }
    setSubmitting(true);
    try {
      const newPost = await createPost({
        userId: user.uid,
        authorName: user.displayName ?? '익명',
        authorPhotoURL: user.photoURL ?? undefined,
        title: title.trim(),
        content: content.trim(),
      });
      setPosts((prev) => [newPost, ...prev]);
      setModalVisible(false);
      setTitle('');
      setContent('');
    } catch {
      Alert.alert('오류', '게시글 작성에 실패했습니다.');
    } finally {
      setSubmitting(false);
    }
  }

  async function handleLike(post: Post) {
    if (!user) return;
    const liked = post.likes.includes(user.uid);
    await toggleLike(post.id, user.uid, liked);
    setPosts((prev) =>
      prev.map((p) =>
        p.id === post.id
          ? {
              ...p,
              likes: liked ? p.likes.filter((id) => id !== user.uid) : [...p.likes, user.uid],
            }
          : p
      )
    );
  }

  async function handleDelete(postId: string) {
    Alert.alert('삭제 확인', '게시글을 삭제하시겠습니까?', [
      { text: '취소', style: 'cancel' },
      {
        text: '삭제',
        style: 'destructive',
        onPress: async () => {
          await deletePost(postId);
          setPosts((prev) => prev.filter((p) => p.id !== postId));
        },
      },
    ]);
  }

  return (
    <SafeAreaView style={styles.safe}>
      <View style={styles.header}>
        <Text style={styles.title}>👥 커뮤니티</Text>
        <TouchableOpacity style={styles.writeBtn} onPress={() => setModalVisible(true)}>
          <Text style={styles.writeBtnText}>+ 글쓰기</Text>
        </TouchableOpacity>
      </View>

      {loading ? (
        <ActivityIndicator size="large" color={Colors.primary} style={{ flex: 1 }} />
      ) : (
        <FlatList
          data={posts}
          keyExtractor={(item) => item.id}
          renderItem={({ item }) => (
            <PostCard
              post={item}
              currentUserId={user?.uid ?? ''}
              onLike={() => handleLike(item)}
              onDelete={() => handleDelete(item.id)}
            />
          )}
          contentContainerStyle={styles.list}
          ListEmptyComponent={
            <View style={styles.empty}>
              <Text style={styles.emptyEmoji}>📝</Text>
              <Text style={styles.emptyText}>아직 게시글이 없어요</Text>
              <Text style={styles.emptySubText}>첫 번째 글을 작성해보세요!</Text>
            </View>
          }
          onRefresh={loadPosts}
          refreshing={loading}
        />
      )}

      <Modal visible={modalVisible} animationType="slide" presentationStyle="pageSheet">
        <KeyboardAvoidingView
          style={{ flex: 1 }}
          behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
        >
          <SafeAreaView style={styles.modal}>
            <View style={styles.modalHeader}>
              <TouchableOpacity onPress={() => setModalVisible(false)}>
                <Text style={styles.cancelText}>취소</Text>
              </TouchableOpacity>
              <Text style={styles.modalTitle}>새 게시글</Text>
              <TouchableOpacity onPress={handleSubmit} disabled={submitting}>
                {submitting ? (
                  <ActivityIndicator color={Colors.primary} />
                ) : (
                  <Text style={styles.submitText}>등록</Text>
                )}
              </TouchableOpacity>
            </View>
            <TextInput
              style={styles.titleInput}
              placeholder="제목을 입력하세요"
              placeholderTextColor={Colors.textMuted}
              value={title}
              onChangeText={setTitle}
              maxLength={50}
            />
            <TextInput
              style={styles.contentInput}
              placeholder="내용을 입력하세요..."
              placeholderTextColor={Colors.textMuted}
              value={content}
              onChangeText={setContent}
              multiline
              textAlignVertical="top"
              maxLength={1000}
            />
          </SafeAreaView>
        </KeyboardAvoidingView>
      </Modal>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: Colors.background },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    backgroundColor: Colors.primary,
    paddingHorizontal: 20,
    paddingVertical: 16,
  },
  title: { fontSize: 20, fontWeight: '800', color: Colors.white },
  writeBtn: {
    backgroundColor: Colors.accent,
    borderRadius: 10,
    paddingHorizontal: 14,
    paddingVertical: 8,
  },
  writeBtnText: { fontSize: 13, fontWeight: '700', color: Colors.text },
  list: { padding: 16 },
  postCard: {
    backgroundColor: Colors.white,
    borderRadius: 16,
    padding: 16,
    marginBottom: 10,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.06,
    shadowRadius: 8,
    elevation: 3,
  },
  postHeader: { flexDirection: 'row', alignItems: 'center', marginBottom: 10 },
  avatar: {
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: Colors.primary,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 10,
  },
  avatarText: { color: Colors.white, fontWeight: '700', fontSize: 15 },
  authorName: { fontSize: 13, fontWeight: '700', color: Colors.text },
  postDate: { fontSize: 11, color: Colors.textMuted },
  deleteBtn: { fontSize: 12, color: Colors.danger, fontWeight: '600' },
  postTitle: { fontSize: 15, fontWeight: '700', color: Colors.text, marginBottom: 6 },
  postContent: { fontSize: 13, color: Colors.textSecondary, lineHeight: 18, marginBottom: 12 },
  postFooter: { flexDirection: 'row', alignItems: 'center', gap: 16 },
  likeBtn: { flexDirection: 'row', alignItems: 'center', gap: 4 },
  likeEmoji: { fontSize: 16 },
  likeCount: { fontSize: 13, fontWeight: '600', color: Colors.textSecondary },
  commentBadge: { flexDirection: 'row', alignItems: 'center', gap: 4 },
  commentEmoji: { fontSize: 16 },
  commentCount: { fontSize: 13, fontWeight: '600', color: Colors.textSecondary },
  empty: { alignItems: 'center', paddingTop: 80 },
  emptyEmoji: { fontSize: 48, marginBottom: 12 },
  emptyText: { fontSize: 16, fontWeight: '600', color: Colors.text },
  emptySubText: { fontSize: 13, color: Colors.textSecondary, marginTop: 4 },
  modal: { flex: 1, backgroundColor: Colors.white },
  modalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: 16,
    borderBottomWidth: 1,
    borderBottomColor: Colors.border,
  },
  cancelText: { fontSize: 15, color: Colors.textSecondary },
  modalTitle: { fontSize: 16, fontWeight: '700', color: Colors.text },
  submitText: { fontSize: 15, fontWeight: '700', color: Colors.primary },
  titleInput: {
    borderBottomWidth: 1,
    borderBottomColor: Colors.border,
    paddingHorizontal: 16,
    paddingVertical: 14,
    fontSize: 16,
    fontWeight: '600',
    color: Colors.text,
  },
  contentInput: {
    flex: 1,
    paddingHorizontal: 16,
    paddingVertical: 14,
    fontSize: 14,
    color: Colors.text,
    lineHeight: 22,
  },
});
