from concurrent import futures
import grpc
from api.user_contracts.v1alpha import user_pb2, user_pb2_grpc

class UserService(user_pb2_grpc.UserServiceServicer):
    def GetUser():
        return
    
def serve():
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))
    user_pb2_grpc.add_UserServiceServicer_to_server(servicer=UserService(), server=server)
    server.add_insecure_port("[::]:50051")
    server.start()
    server.wait_for_termination()